//
//  HabitStatistics.swift
//  Habits
//
//  Created by Long Tran on 23/03/2024.
//

import Foundation


struct HabitStatistics{
    let habit: Habit
    let userCounts: [UserCount]
}
                     
 extension HabitStatistics: Codable{
        
}
