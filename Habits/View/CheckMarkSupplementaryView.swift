//
//  CheckMarkSupplementaryItem.swift
//  Habits
//
//  Created by Long Tran on 03/04/2024.
//

import UIKit

class CheckMarkSupplementaryView: UICollectionReusableView {
    
    let imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "person.fill.checkmark"))
        
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("init(coder:) has not been implemented")
    }
    
}
