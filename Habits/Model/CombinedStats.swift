//
//  CombinedStats.swift
//  Habits
//
//  Created by Long Tran on 25/03/2024.
//

import Foundation


struct CombinedStats{
    let userStatistics: [UserStatistics]
    let habitStatistics: [HabitStatistics]
    
}

extension CombinedStats: Codable {}
