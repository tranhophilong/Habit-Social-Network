//
//  ApiRequest.swift
//  Habits
//
//  Created by Long Tran on 22/03/2024.
//

import Foundation


protocol APIRequest{
    
    associatedtype Response
    
    var path: String {get}
    var queryItems: [URLQueryItem]? {get}
    var request: URLRequest {get}
    var postData: Data? {get}
    
}

extension APIRequest{
    var host: String { "localHost"}
    var port: Int {8080}
}

extension APIRequest{
    var queryItems: [URLQueryItem]? {nil}
    var postData: Data? {nil}
}

extension APIRequest{
    var request: URLRequest{
        var components = URLComponents()
        
        components.scheme = "http"
        components.host = host
        components.port = port
        components.path = path
        components.queryItems = queryItems
        
        var request = URLRequest(url: components.url!)
        
        if let data = postData{
            request.httpBody = data
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        return request
    }
}


enum APIRequestError: Error{
    case itemsNotFound
    case requestFaild
    
}

extension APIRequest where Response: Decodable{
    func send() async throws -> Response{
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else{
            throw APIRequestError.itemsNotFound
        }
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Response.self, from: data)
        
        return decoded
    }
}

