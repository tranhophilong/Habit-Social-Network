//
//  SupplementaryItem.swift
//  Habits
//
//  Created by Long Tran on 03/04/2024.
//

import Foundation

enum SupplementaryItemType{
    case collectionSupplementaryView
    case layoutDecorationView
}

protocol SupplementaryItem{
    var itemType: SupplementaryItemType { get }
    
    var viewKind: String { get }
}
