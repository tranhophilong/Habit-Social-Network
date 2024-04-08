//
//  ImageRequestController.swift
//  Habits
//
//  Created by Long Tran on 04/04/2024.
//

import UIKit


class ImageRequestController{
    
   private let cache: NSCache = NSCache<NSURL, UIImage>()
    
    func fetchImage(from imageId: String) async throws -> UIImage{
        let imageRequest = ImageRequest(imageID: imageId)
        let image =  try await imageRequest.send()
        
        let nsurl = NSURL(string: imageRequest.request.url!.absoluteString)!
        
        cache.setObject(image, forKey: nsurl)
        
        
        return image
    }
    
    func getImage(from imageId: String, placeholder: UIImage = UIImage(systemName: "photo")!) -> UIImage{
        let imageRequest = ImageRequest(imageID: imageId)
        
        guard let nsurl = NSURL(string: imageRequest.request.url!.absoluteString) else{
            return placeholder
        }
        
        if let image = cache.object(forKey: nsurl) {
            return image
        }
                
        return placeholder
    }
}

