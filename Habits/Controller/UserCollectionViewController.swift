//
//  UserCollectionViewController.swift
//  Habits
//
//  Created by Long Tran on 22/03/2024.
//

import UIKit


class UserCollectionViewController: UICollectionViewController {
    
    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.section, ViewModel.Item.ID>
    
    enum Layout{
        case grid
        case column
        
    }
    
    enum DecorationView: String, SupplementaryItem{
        case checkMark
        
        var itemType: SupplementaryItemType {
            switch self{
            case .checkMark:
                return .layoutDecorationView
            }
            
        }
        
        var viewKind: String {
            return rawValue
        }
        
    }
    
    enum ViewModel{
        typealias section = Int
        
        struct Item: Identifiable, Equatable{
            var id: String{
                return user.id
            }
            let user: User
            let isFollowed: Bool
            
            
            static func == (lhs: Item, rhs: Item) -> Bool {
                return lhs.id == rhs.id
            }
            
        }
    }
    
    struct Model{
        var usersByID = [String: User]()
        var followedUsers: [User]{
            return Array(usersByID.filter{
                Settings.shared.followedUserIDs.contains($0.key)
            }.values)
        }
    }
    
    var dataSource: DataSourceType!
    var model = Model()
    var items: [ViewModel.Item] = []
    
    var userRequestTask: Task<Void, Never>? = nil
    var imageRequestTasks: [IndexPath: Task<Void, Never>] = [:]
    
    let imageRequestController = ImageRequestController()
    
    @IBOutlet weak var layoutButton: UIBarButtonItem!
    
    var layout: [Layout: UICollectionViewLayout] = [:]
    var activeLayout: Layout = .grid{
        didSet{
            if let layout = layout[activeLayout]{
                var snapshot = dataSource.snapshot()
                let visibleIds = collectionView.indexPathsForVisibleItems.compactMap({dataSource.itemIdentifier(for: $0)})
                snapshot.reloadItems(visibleIds)
                
                dataSource.apply(snapshot, animatingDifferences: true)
                
                collectionView.setCollectionViewLayout(layout, animated: true) { _ in
                    switch self.activeLayout{
                        
                    case .grid:
                        self.layoutButton.image = UIImage(systemName: "rectangle.grid.1x2")
                    case .column:
                        self.layoutButton.image =  UIImage(systemName: "rectangle.grid.2x2")

                    }
                }
            }
        }
    }
    
    
    deinit{ 
        userRequestTask?.cancel()
        imageRequestTasks.values.forEach { task in
            task.cancel()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.layoutButton.image = UIImage(systemName: "rectangle.grid.1x2")
        layout[.grid] = generateGridLayout()
        layout[.column] = generateColumnLayout()
        
        dataSource = createDataSource()
        collectionView.dataSource = dataSource
        
        if let layout = layout[activeLayout]{
            collectionView.collectionViewLayout = layout
        }
        update()
        
    }
  
    @IBAction func layoutButtonTapped(_ sender: Any) {
        activeLayout = activeLayout == .grid ? .column : .grid
    }
    
    func update(){
        userRequestTask?.cancel()
        imageRequestTasks.values.forEach { task in
            task.cancel()
        }
        
        
        imageRequestTasks = [:]
        
        userRequestTask = Task{
            if let users = try? await UserRequest().send(){
                model.usersByID = users
            }else{
                model.usersByID = [:]
            }
            
            updateCollectionView()
            userRequestTask = nil
        }
    }
    
    func updateCollectionView(){
        items = model.usersByID.values.sorted().reduce(into: [ViewModel.Item](), { partialResult, user in
            partialResult.append(ViewModel.Item(user: user, isFollowed: model.followedUsers.contains(user)))
            
        })
        
        let userIDs = items.map(\.id)
        
        let itemsBySection = [0: userIDs]
        
        
        
        dataSource.applySnapshotUsing(sectionIDs: [0], itemBySections: itemsBySection)
    }
    
    func createDataSource() -> DataSourceType{
        
        let cellHandler : UICollectionView.CellRegistration<UserCollectionViewCell, ViewModel.Item.ID>.Handler = {[weak self] cell, indexPath, itemIdentifier in
            guard let self, let item = items.first(where: {$0.id == itemIdentifier}) else { return }
            
            
            cell.update(imageRequestController: imageRequestController, user: item.user)
            
            cell.imageView.layer.cornerRadius = 10
            
            var backgroudConfiguration = UIBackgroundConfiguration.clear()
            backgroudConfiguration.backgroundColor = item.user.color?.uiColor ??  UIColor.systemGray4
            backgroudConfiguration.cornerRadius = 8
            cell.backgroundConfiguration = backgroudConfiguration
            
            if cell.imageView.image == UserCollectionViewCell.placeholder{
                imageRequestTasks[indexPath]?.cancel()
                imageRequestTasks[indexPath] = Task{ [weak self] in
                    guard let self else { return }
                    
                    defer{
                        imageRequestTasks[indexPath] = nil
                        
                    }
                    
                    if let _ = try? await imageRequestController.fetchImage(from: item.user.id){
                        var snapshot = dataSource.snapshot()
                        snapshot.reconfigureItems([itemIdentifier])
                        
                        await dataSource.apply(snapshot, animatingDifferences: true)
                    }
                          
                }
            }
            
            
        }
        
        let gridCellNib = UINib(nibName: "UserCollectionViewCell + Grid", bundle: Bundle(for: UserCollectionViewCell.self))
        let gridCellRegistration = UICollectionView.CellRegistration<UserCollectionViewCell, ViewModel.Item.ID>(cellNib: gridCellNib, handler: cellHandler)
        
        let columnCellNib = UINib(nibName: "UserCollectionView + Column", bundle: Bundle(for: UserCollectionViewCell.self))
        let columnCellRegistration = UICollectionView.CellRegistration<UserCollectionViewCell, ViewModel.Item.ID>(cellNib: columnCellNib, handler: cellHandler)
        

        
        let datasource = DataSourceType(collectionView: collectionView) {[weak self] collectionView, indexPath, itemIdentifier in
            guard let self else { return nil }
            switch activeLayout {
            case .grid:
                return collectionView.dequeueConfiguredReusableCell(using: gridCellRegistration, for: indexPath, item: itemIdentifier)
            case .column:
                return collectionView.dequeueConfiguredReusableCell(using: columnCellRegistration, for: indexPath, item: itemIdentifier)
            }
        }
        
        let supplementaryItemRegistration = UICollectionView.SupplementaryRegistration<CheckMarkSupplementaryView>(elementKind: DecorationView.checkMark.viewKind) {[weak self] checkMarkView, elementKind, indexPath in
            
            guard let self, let itemIndentifier = datasource.itemIdentifier(for: indexPath),  let item =  items.first(where: {$0.id == itemIndentifier})  else {
                return
            }
            
            
            checkMarkView.imageView.isHidden = !item.isFollowed
            
        }
                
        datasource.supplementaryViewProvider = {collectionView, elementKind, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(using: supplementaryItemRegistration, for: indexPath)
            
            
        }
        

        return datasource
    }
    

    
    func generateGridLayout() -> UICollectionViewLayout{
        let padding: CGFloat = 20
    
        let supplementaryItemSize = NSCollectionLayoutSize(widthDimension: .absolute(45),
                                                          heightDimension: .absolute(45))
        let supplementaryItemPlace = NSCollectionLayoutAnchor(edges: [.top, .trailing], fractionalOffset: CGPoint(x: 0.2, y: 0))
        let supplementaryItem = NSCollectionLayoutSupplementaryItem(layoutSize: supplementaryItemSize,
                                                           elementKind: DecorationView.checkMark.viewKind,
                                                                   containerAnchor: supplementaryItemPlace)
        
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)), supplementaryItems: [supplementaryItem])
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1/4)), subitem: item, count: 2)
        group.interItemSpacing = .fixed(padding)
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: padding, bottom: 0, trailing: padding)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = padding
        section.contentInsets = NSDirectionalEdgeInsets(top: padding, leading: 0, bottom: padding, trailing: 0)
        
        return UICollectionViewCompositionalLayout(section: section)
        }
    
    func generateColumnLayout() -> UICollectionViewLayout{
        let padding: CGFloat = 20
        
        let supplementaryItemSize = NSCollectionLayoutSize(widthDimension: .absolute(45),
                                                          heightDimension: .absolute(45))
        let supplementaryItemPlace = NSCollectionLayoutAnchor(edges: [.top, .trailing])
        let supplementaryItem = NSCollectionLayoutSupplementaryItem(layoutSize: supplementaryItemSize,
                                                           elementKind: DecorationView.checkMark.viewKind,
                                                                   containerAnchor: supplementaryItemPlace)
        
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)), supplementaryItems: [supplementaryItem])
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(120)), subitem: item, count: 1)
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: padding, bottom: 0, trailing: padding)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = padding
        section.contentInsets = NSDirectionalEdgeInsets(top: padding, leading: 0, bottom: padding, trailing: 0)
        
        return UICollectionViewCompositionalLayout(section: section)
        
    }
        
    
 
 
    
//    MARK: Delegate
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        let config = UIContextMenuConfiguration(actionProvider:  { [weak self] _ in
            guard let self, let indexPath = indexPaths.first, let itemIndentifier = dataSource.itemIdentifier(for: indexPath), let item = items.first(where: {$0.id == itemIndentifier}) else {return nil}
            
            let uiMenu: UIMenu?
            
            if item.user.id == Settings.shared.currentUser.id{
                uiMenu = nil
            }else{
                let followedToggle = UIAction(title: item.isFollowed ? "Unfollow" : "Follow") { action in
                    Settings.shared.toggleFollowed(item.user)
                    self.updateCollectionView()
                 
                }
                uiMenu = UIMenu(title: "", children: [followedToggle])
            }
            
            return uiMenu
        })
        
        return config
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let itemIdentifier = dataSource.itemIdentifier(for: indexPath), let item = items.first(where: {$0.id == itemIdentifier}) else {return}
    
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: UserDetailViewController.self))
        let controller = storyboard.instantiateViewController(identifier: "UserDetailViewController") { coder in
            UserDetailViewController(coder: coder, user: item.user)
        }
        
        navigationController?.pushViewController(controller, animated: true)
    }

}
