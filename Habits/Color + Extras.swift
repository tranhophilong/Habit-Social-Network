//
//  Color + Extras.swift
//  Habits
//
//  Created by Long Tran on 27/03/2024.
//

import UIKit

let favoriteHabitColor = UIColor(hue: 0.15, saturation: 1, brightness: 0.9, alpha: 1)

extension Color{
    var uiColor: UIColor{
        return UIColor(hue: CGFloat(hue), saturation: CGFloat(saturation), brightness: CGFloat(brightness), alpha: 1)
    }
    
    
}
