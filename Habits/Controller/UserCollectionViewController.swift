//
//  UserCollectionViewController.swift
//  Habits
//
//  Created by Long Tran on 22/03/2024.
//

import UIKit


class UserCollectionViewController: UICollectionViewController {
    
    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.section, ViewModel.Item.ID>
    
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
    deinit{ userRequestTask?.cancel()}
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = createDataSource()
        collectionView.dataSource = dataSource
        collectionView.collectionViewLayout = createLayout()
        
        update()
    }

    func update(){
        userRequestTask?.cancel()
        
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
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, ViewModel.Item.ID> { [weak self] cell, indexPath, itemIdentifier in
            guard let self, let item = items.first(where: {$0.id == itemIdentifier}) else {return}
            
            var content = cell.defaultContentConfiguration()
            content.text = item.user.name
            content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 11, leading: 8, bottom: 11, trailing: 8)
            content.textProperties.alignment = .center
            cell.contentConfiguration = content
            
            var backgroudConfiguration = UIBackgroundConfiguration.clear()
            backgroudConfiguration.backgroundColor = .systemGray4
            backgroudConfiguration.cornerRadius = 8
            cell.backgroundConfiguration = backgroudConfiguration
            
        }
        
        let datasource = DataSourceType(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
        }
        
        return datasource
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout{
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalHeight(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(0.45))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item, item])
        group.interItemSpacing = .fixed(20)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 20
        section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
//    MARK: Delegate
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        let config = UIContextMenuConfiguration(actionProvider:  { [weak self] _ in
            guard let self, let indexPath = indexPaths.first, let itemIndentifier = dataSource.itemIdentifier(for: indexPath), let item = items.first(where: {$0.id == itemIndentifier}) else {return nil}
            
            
            let followedToggle = UIAction(title: item.isFollowed ? "Unfollow" : "Follow") { action in
                Settings.shared.toggleFollowed(item.user)
                self.updateCollectionView()
            }
            
            return UIMenu(title: "", children: [followedToggle])
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
