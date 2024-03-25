//
//  UserStatistics.swift
//  Habits
//
//  Created by Long Tran on 23/03/2024.
//

import Foundation

struct UserStatistics{
    let user: User
    let habitCounts: [HabitCount]
}

extension UserStatistics: Codable{}
