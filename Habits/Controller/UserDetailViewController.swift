//
//  UserDetailViewController.swift
//  Habits
//
//  Created by Long Tran on 22/03/2024.
//

import UIKit

class UserDetailViewController: UIViewController {
    
    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item.ID>
    
    enum SectionHeader: String{
        case kind = "SectionHeader"
        case reuse = "HeaderView"
        
        var identifier: String{
            return rawValue
        }
    }
    
    enum ViewModel{
        
        enum Section: Hashable, Comparable{
           
            case leading
            case category(_ category: Category)
            
            var sectionColor: UIColor{
                switch self{
                    
                case .leading:
                    return .systemGray4
                case .category(let category):
                    return category.color.uiColor
                }
            }
            
            static func < (lhs: Section, rhs: Section) -> Bool {
                switch (lhs, rhs){
                case (.leading, .category) , (.leading, .leading):
                    return true
                case (.category, .leading):
                    return false
                case (category(let category1), category(let category2)):
                    return category1.name > category2.name
                }
                
            }
            
        }
        
        typealias Item = HabitCount
        
        
    }
    
    struct Model{
        var userStats: UserStatistics?
        var leadingStats: UserStatistics?
    }

    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var user: User!
    
    var dataSource: DataSourceType!
    var model = Model()
    var items: [ViewModel.Item] = []
    
    var imageRequestTask: Task<Void, Never>? = nil
    var userStatisticsRequestTask: Task<Void, Never>? = nil
    var habitLeadStatisticsRequestTask: Task<Void, Never>? = nil
    
    var updateTimer: Timer?
    
    deinit { 
        imageRequestTask?.cancel()
        userStatisticsRequestTask?.cancel()
        habitLeadStatisticsRequestTask?.cancel()
    }
  
    init?(coder: NSCoder, user: User) {
        super.init(coder: coder)
        self.user = user
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userNameLabel.textColor = user.color?.uiColor ?? .black
//        let tabBarApearance = UITabBarAppearance()
//        tabBarApearance.backgroundColor  = .quaternarySystemFill
//        tabBarController?.tabBar.scrollEdgeAppearance = tabBarApearance
//        
//        let navBarAppearrance = UINavigationBarAppearance()
//        navBarAppearrance.backgroundColor = .quaternarySystemFill
//        navigationItem.scrollEdgeAppearance = navBarAppearrance
        
        navigationItem.largeTitleDisplayMode = .never
        
        bioLabel.text = user.bio
        userNameLabel.text = user.name
        
//        collectionView.register(NameSectionHeaderView.self, forSupplementaryViewOfKind: SectionHeader.kind.identifier, withReuseIdentifier: SectionHeader.reuse.identifier)
//        
        dataSource = createDataSource()
        collectionView.dataSource = dataSource
        collectionView.collectionViewLayout = createLayout()
        
        update()
        
        imageRequestTask = Task{
            if let image = try? await ImageRequest(imageID: user.id).send(){
                self.profileImageView.image = image
            }
            
            imageRequestTask = nil
        }
        
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        update()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { _ in
            self.update()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    func update(){
        userStatisticsRequestTask?.cancel()
        userStatisticsRequestTask = Task{
            if let userStats = try? await UserStatisticsRequest(userIDs: [user.id]).send(), userStats.count > 0{
                model.userStats = userStats[0]
            }else{
                model.userStats = nil
            }
            
            self.updateCollectionView()
            habitLeadStatisticsRequestTask = nil
        }
        
        
        habitLeadStatisticsRequestTask?.cancel()
        habitLeadStatisticsRequestTask = Task{
            if let userStats = try? await HabitLeadStatisticsRequest(userId: user.id ).send(){
                self.model.leadingStats = userStats
            }else{
                self.model.leadingStats = nil
            }
            self.updateCollectionView()
            habitLeadStatisticsRequestTask = nil
        }
        
    }
    
    func updateCollectionView(){
        guard let userStats = model.userStats, let leadingStats = model.leadingStats else {return}
        
        var itemsBySection = userStats.habitCounts.reduce(into: [ViewModel.Section: [ViewModel.Item]]()) { partialResult, habitCount in
            
            let section: ViewModel.Section
            
            if leadingStats.habitCounts.contains(habitCount){
                section = .leading
            }else{
                section = .category(habitCount.habit.category)
            }
            
            partialResult[section, default: []].append(habitCount)
            
        }
        
        itemsBySection = itemsBySection.mapValues{$0.sorted()}
        items = itemsBySection.values.reduce([], +)
        let sectionIDs = itemsBySection.keys.sorted()
        
        dataSource.applySnapshotUsing(sectionIDs: sectionIDs, itemBySections: itemsBySection.mapValues({$0.map(\.id)}))
    }
    
    
    func createDataSource() -> DataSourceType{
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, ViewModel.Item.ID> {[weak self] cell, indexPath, itemIdentifier in
            guard let self, let habitStat = items.first(where: {$0.id == itemIdentifier}) else {return}
            
            var content = cell.defaultContentConfiguration()
            content.text = habitStat.habit.name
            content.secondaryText = "\(habitStat.count)"
            
            content.prefersSideBySideTextAndSecondaryText = true
            content.textProperties.font = .preferredFont(forTextStyle: .headline)
            content.secondaryTextProperties.font = .preferredFont(forTextStyle: .body)
            cell.contentConfiguration = content
      
        }
        
        let dataSource = DataSourceType(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration<NameSectionHeaderView>(elementKind: SectionHeader.kind.identifier) { header, elementKind, indexPath in
            let section  = dataSource.snapshot().sectionIdentifiers[indexPath.section]
            
            switch section{
                
            case .leading:
                header.nameLabel.text = "Leading"
            case .category(let category):
                header.nameLabel.text = category.name
            }
            
            header.backgroundColor = section.sectionColor
    
        }
        
        dataSource.supplementaryViewProvider = {collectionView, category, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        
        return dataSource
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout{
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 12)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(44))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(36))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: SectionHeader.kind.identifier, alignment: .top)
        sectionHeader.pinToVisibleBounds = true
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)
        section.boundarySupplementaryItems = [sectionHeader]
        return UICollectionViewCompositionalLayout(section: section)
    }
    
   
}
