//
//  LoggedHabit.swift
//  Habits
//
//  Created by Long Tran on 24/03/2024.
//

import Foundation


struct LoggedHabit{
    let userID: String
    let habitName: String
    let timestamp: Date
}


extension LoggedHabit: Codable{
    
}
