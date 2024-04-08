//
//  FollwedCollectionViewCell.swift
//  Habits
//
//  Created by Long Tran on 25/03/2024.
//

import UIKit

class FollowedCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var separatorLineView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var separatorLineViewHeightContraint: NSLayoutConstraint!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        separatorLineViewHeightContraint.constant = 1 / UITraitCollection.current.displayScale
    }

}



