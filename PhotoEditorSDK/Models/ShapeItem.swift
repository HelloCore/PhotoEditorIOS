//
//  ShapeItem.swift
//  PhotoEditorSDK
//
//  Created by Akkharawat Chayapiwat on 8/8/18.
//  Copyright © 2018 Akkharawat Chayapiwat. All rights reserved.
//

import Foundation
import UIKit

enum ShapeType {
    case circle
    case rectangular
    case square
}

class ShapeItem {
    
    let imageView: UIImageView
    
    var lineWidth: CGFloat {
        set (newValue) {
            self.imageView.layer.borderWidth = newValue
        }
        get {
            return self.imageView.layer.borderWidth
        }
    }
    
    var color: UIColor {
        set (color) {
            self.imageView.layer.borderColor = color.cgColor
        }
        get {
            if let borderColor = self.imageView.layer.borderColor {
                return UIColor(cgColor: borderColor)
            }
            return UIColor.clear
        }
    }
    
    
    init(type: ShapeType, parent: UIView, lineWidth: CGFloat, color: UIColor) {
        let width: CGFloat = 70
        var height: CGFloat = 70
        if type == .rectangular {
            height = 40
        }
        
        let frame = CGRect(x: (UIScreen.main.bounds.size.width - width) / 2,
                           y: (UIScreen.main.bounds.size.height - height) / 2,
                           width: width,
                           height: height)
        let newFrame = UIApplication.shared.keyWindow?.convert(frame, to: parent) ?? frame
        self.imageView = UIImageView(frame: newFrame)
        
        self.imageView.layer.borderColor = color.cgColor
        self.imageView.layer.borderWidth = lineWidth
        self.imageView.isUserInteractionEnabled = true
        if type == .circle {
            self.imageView.layer.cornerRadius = newFrame.size.width / 2
        }
    }
}
