//
//  UserCollectionViewCell.swift
//  Habits
//
//  Created by Long Tran on 04/04/2024.
//

import UIKit

class UserCollectionViewCell: UICollectionViewCell {
    static let placeholder =  UIImage(systemName: "photo")!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    
    }
    
    
}

@MainActor
extension UserCollectionViewCell{
    func update(imageRequestController: ImageRequestController, user: User){
     
        imageView.image = imageRequestController.getImage(from: user.id, placeholder: UserCollectionViewCell.placeholder)
        nameLabel.text = user.name
    }
}
