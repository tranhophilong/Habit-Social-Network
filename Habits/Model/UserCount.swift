//
//  UserCount.swift
//  Habits
//
//  Created by Long Tran on 23/03/2024.
//

import Foundation


struct UserCount{
    let user: User
    let count: Int
}


extension UserCount: Codable{}

extension UserCount: Hashable {}
