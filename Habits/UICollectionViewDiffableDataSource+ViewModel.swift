//
//  UICollectionViewDiffableDataSource+ViewModel.swift
//  Habits
//
//  Created by Long Tran on 22/03/2024.
//

import UIKit


extension UICollectionViewDiffableDataSource{
    
    func applySnapshotUsing(sectionIDs: [SectionIdentifierType], itemBySections: [SectionIdentifierType: [ItemIdentifierType]], sectionsRetainedIfEmpty: Set<SectionIdentifierType> = Set<SectionIdentifierType>()){
        applySnapshotUsing(sectionIDs: sectionIDs, itemBySections: itemBySections, animatingDifferences: true, sectionsRetainedIfEmpty: sectionsRetainedIfEmpty)
    }
    
    func applySnapshotUsing(sectionIDs: [SectionIdentifierType], itemBySections: [SectionIdentifierType: [ItemIdentifierType]], animatingDifferences: Bool, sectionsRetainedIfEmpty: Set<SectionIdentifierType> = Set<SectionIdentifierType>()){
        
        var snapshot = NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>()
        
        for sectionID in sectionIDs {
            guard let sectionItems = itemBySections[sectionID], sectionItems.count > 0 || sectionsRetainedIfEmpty.contains(sectionID) else { continue }
            
            snapshot.appendSections([sectionID])
            snapshot.appendItems(sectionItems, toSection: sectionID)
            snapshot.reloadItems(sectionItems)
        }
        
        self.apply(snapshot, animatingDifferences: animatingDifferences)
        
    }
}
