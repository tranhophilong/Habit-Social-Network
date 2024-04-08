//
//  APIService.swift
//  Habits
//
//  Created by Long Tran on 22/03/2024.
//

import UIKit

struct HabitRequest: APIRequest{
    typealias Response = [String: Habit]
    
    var path: String {"/habits"}
       
}

struct UserRequest: APIRequest{
    typealias Response = [String: User]
    
    var path: String {"/users"}
    
    
    
}

struct HabitStatisticsRequest: APIRequest{
    typealias Response = [HabitStatistics]
    
    var path: String {"/habitStats"}
    
    var habitNames: [String]?
     
    var queryItems: [URLQueryItem]?{
        if let habitNames = habitNames{
            return [URLQueryItem(name: "names", value: habitNames.joined(separator: ","))]
        }else{
            return nil
        }
    }
    
}

struct UserStatisticsRequest: APIRequest{
    typealias Response = [UserStatistics]
    
    var path: String {"/userStats"}
    
    var userIDs: [String]?
    
    var queryItems: [URLQueryItem]?{
        if let userIds = userIDs{
            return [URLQueryItem(name: "ids", value: userIds.joined(separator: ","))]
        }else{
            return nil
        }
    }
    
    
}

struct HabitLeadStatisticsRequest: APIRequest{
    typealias Response = UserStatistics
    
    var userId: String
    
    var path: String {"/userLeadingStats/\(userId)"}
    
    
}

struct ImageRequest: APIRequest{
    typealias Response = UIImage
    
    var imageID: String
    
    var path: String {"/images/" + imageID}
    
}


struct LogHabitRequest: APIRequest{
    typealias Response = Void
    
    var path: String {"/loggedHabit"}
    
    var loggedHabit: LoggedHabit
    
    var postData: Data?{
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        return try! encoder.encode(loggedHabit)
    }
    
    
}

struct CombinedStatsRequest: APIRequest{
    typealias Response = CombinedStats
    
    var path: String {"/combinedStats"}
    
    
}
