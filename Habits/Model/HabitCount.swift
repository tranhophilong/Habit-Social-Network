//
//  HabitCount.swift
//  Habits
//
//  Created by Long Tran on 23/03/2024.
//

import Foundation


struct HabitCount{
    let habit: Habit
    let count: Int
}

extension HabitCount: Codable {}


extension HabitCount: Identifiable{
    var id: String{
        return habit.id
    }
}

extension HabitCount: Equatable{
    static func ==(_ lhs: HabitCount, _ rhs: HabitCount) -> Bool{
        return lhs.id == rhs.id
    }
}

extension HabitCount: Comparable{
    static func < (lhs: HabitCount, rhs: HabitCount) -> Bool {
        return lhs.habit < rhs.habit
    }
    
    
}
