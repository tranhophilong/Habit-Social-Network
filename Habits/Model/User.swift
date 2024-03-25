//
//  User.swift
//  Habits
//
//  Created by Long Tran on 23/03/2024.
//

import Foundation


struct User{
    let id: String
    let name: String
    let color: Color?
    let bio: String?
}

extension User: Codable {}

extension User: Hashable{
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }
    
}

extension User: Comparable{
    static func < (lhs: User, rhs: User) -> Bool {
        return lhs.name < rhs.name
    }
    
    
}
