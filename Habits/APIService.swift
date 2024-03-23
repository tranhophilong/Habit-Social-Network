//
//  APIService.swift
//  Habits
//
//  Created by Long Tran on 22/03/2024.
//

import Foundation

struct HabitRequest: APIRequest{
    
    typealias Response = [String: Habit]
    
    var path: String {"/habits"}
    
    
    
    
}


struct UserRequest: APIRequest{
    typealias Response = [String: User]
    
    var path: String {"/users"}
    
    
}
