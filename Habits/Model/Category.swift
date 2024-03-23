//
//  Category.swift
//  Habits
//
//  Created by Long Tran on 22/03/2024.
//

import Foundation

struct Category{
    let name: String
    let color: Color
}

extension Category: Codable {}

extension Category: Hashable{
    static func == (lhs: Category, rhs: Category) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        return hasher.combine(name)
    }
}
