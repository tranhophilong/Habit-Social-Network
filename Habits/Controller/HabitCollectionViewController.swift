//
//  HabitCollectionViewController.swift
//  Habits
//
//  Created by Long Tran on 22/03/2024.
//

import UIKit


class HabitCollectionViewController: UICollectionViewController {
    
    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item.ID>
    
    enum ViewModel{
        enum Section: Hashable, Comparable{
            
            case favorite
            case category(_ category: Category)
            
            var sectionColor: UIColor{
                switch self{
                    
                case .favorite:
                    return favoriteHabitColor
                case .category(let category):
                    return category.color.uiColor
                }
            }
            
            static func < (lhs: Section, rhs: Section) -> Bool {
                switch (lhs, rhs){
                    
                case (.category(let l), .category(let r)): return l.name < r.name
                case (.favorite, _): return true
                case (_, .favorite): return false
                    
                }
            }
        }
        
        typealias Item = Habit
    }
    
    enum SectionHeader: String{
        case kind = "SectionHeader"
        
        var identifier: String{
            return rawValue
        }
        
        
    }
    
    struct Model{
        var habitsByName = [String: Habit]()
        var favoriteHabits: [Habit]{
            return Settings.shared.favoriteHabits
        }
    }
    
    var model = Model()
    var dataSource: DataSourceType!
    var items: [ViewModel.Item] = []
    
    var habitsRequestTask: Task<Void, Never>? = nil
    deinit{ habitsRequestTask?.cancel() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = createDataSource()
        collectionView.dataSource  = dataSource
        collectionView.collectionViewLayout = createLayout()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        update()
    }
    
    func update(){
        habitsRequestTask?.cancel()
        habitsRequestTask = Task{
            if let habits = try? await HabitRequest().send(){
                model.habitsByName = habits
            }else{
                model.habitsByName = [:]
            }
            
            updateCollectionView()
            habitsRequestTask = nil
        }
        
        
    }
    
    func updateCollectionView(){
        var itemsBySection = model.habitsByName.values.reduce(into: [ViewModel.Section: [ViewModel.Item]]()) { partialResult, habit in
            let item = habit
            
            let section: ViewModel.Section
            if model.favoriteHabits.contains(habit){
                section = .favorite
            }else{
                section = .category(habit.category)
            }
            
            partialResult[section, default: []].append(item)
        }
        
        itemsBySection = itemsBySection.mapValues({$0.sorted()})
        
        items = itemsBySection.values.reduce([], +)
        
        let sectionIDs = itemsBySection.keys.sorted()
        dataSource.applySnapshotUsing(sectionIDs: sectionIDs, itemBySections: itemsBySection.mapValues({$0.map(\.id)}))
    }
    
    func configCell(_ cell: UICollectionViewListCell, withItem item: ViewModel.Item){
        var content   = cell.defaultContentConfiguration()
        content.text = item.name
        cell.contentConfiguration = content
    }
    
    func createDataSource() -> DataSourceType{
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, ViewModel.Item.ID>{ [weak self] cell, indexPath, itemIdentifier in
            guard let self, let item = items.first(where: {$0.id == itemIdentifier}) else {return}
            
            configCell(cell, withItem: item)
        }
        
        let dataSource = DataSourceType(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration<NameSectionHeaderView>(elementKind: SectionHeader.kind.identifier) { header, elementKind, indexPath in
            let section = dataSource.snapshot().sectionIdentifiers[indexPath.section]
            
            switch section{
            case .favorite:
                header.nameLabel.text = "Favorite"
            case .category(let category):
                header.nameLabel.text = category.name
            }
            
            header.backgroundColor = section.sectionColor
        }
        
        dataSource.supplementaryViewProvider = {collectionView, kind, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        
        return dataSource
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(44))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(36))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: SectionHeader.kind.identifier, alignment: .top)
        sectionHeader.pinToVisibleBounds  = true
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
        section.boundarySupplementaryItems = [sectionHeader]
        
        return UICollectionViewCompositionalLayout(section: section)
        
        
    }
    
//     MARK: Delegate
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        let config = UIContextMenuConfiguration(actionProvider:  { [weak self] _ in
            guard let self, let indexPath = indexPaths.first, let itemIndentifier = dataSource.itemIdentifier(for: indexPath), let item = items.first(where: {$0.id == itemIndentifier}) else {return nil}
            
            
            let favoriteToggle = UIAction(title: model.favoriteHabits.contains(item) ? "Unfavorite" : "Favorite") { action in
                Settings.shared.toggleFavorite(item)
                self.updateCollectionView()
            }
            
            return UIMenu(title: "", children: [favoriteToggle])
        })
        
        return config
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let itemIdentiifer = dataSource.itemIdentifier(for: indexPath), let item = items.first(where: {$0.id == itemIdentiifer}) else {return}
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: HabitDetailViewController.self))
        
        let controller = storyboard.instantiateViewController(identifier: "HabitDetailViewController") { coder in
            HabitDetailViewController(coder: coder, habit: item)
        }
    
        navigationController?.pushViewController(controller, animated: true)
                
    }
    
}

