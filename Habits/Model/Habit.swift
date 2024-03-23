//
//  Habit.swift
//  Habits
//
//  Created by Long Tran on 22/03/2024.
//

import Foundation

struct Habit{
    let name: String
    let category: Category
    let info: String
}

extension Habit: Codable {}

extension Habit: Identifiable{
    var id: String {
        return name
    }
    
}

extension Habit: Equatable{
    static func == (lhs: Habit, rhs: Habit) -> Bool {
        return lhs.id == rhs.id
    }
    
}

extension Habit: Comparable{
    static func < (lhs: Habit, rhs: Habit) -> Bool {
        lhs.name < rhs.name
    }
    
    
}


