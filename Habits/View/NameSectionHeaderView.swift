//
//  NameSectionHeaderView.swift
//  Habits
//
//  Created by Long Tran on 22/03/2024.
//

import UIKit

class NameSectionHeaderView: UICollectionReusableView {
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.boldSystemFont(ofSize: 17)
        
        return label
    }()
    
    var _centerYContraint: NSLayoutConstraint?
    var centerYContraint: NSLayoutConstraint{
        if _centerYContraint == nil{
            _centerYContraint = nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        }
        
        return _centerYContraint!
    }
    
    var _topYContraint: NSLayoutConstraint?
    var topYContraint: NSLayoutConstraint{
        if _topYContraint == nil{
            _topYContraint = nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12)
            
        }
        
        return _topYContraint!
    }
    
    func alignLabelToTop(){
        topYContraint.isActive = true
        centerYContraint.isActive = false
    }
    
    func alignLabelToYCenter(){
        topYContraint.isActive = false
        centerYContraint.isActive = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView(){
        backgroundColor = .systemGray5
        
        addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
        ])
            alignLabelToYCenter()
    }
    
    
}
