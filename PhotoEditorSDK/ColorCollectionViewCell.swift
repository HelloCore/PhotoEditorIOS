//
//  ColorCollectionViewCell.swift
//  PhotoEditorSDK
//
//  Created by Akkharawat Chayapiwat on 8/6/18.
//  Copyright © 2018 Akkharawat Chayapiwat. All rights reserved.
//

import UIKit

class ColorCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var colorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        colorView.layer.cornerRadius = colorView.frame.width / 2
        colorView.clipsToBounds = true
    }
    
    func configureCellWithColor(_ color: UIColor, isSelected: Bool) {
        colorView.backgroundColor = color
        if color == UIColor.white {
            colorView.layer.borderColor = UIColor.black.cgColor
        }else{
            colorView.layer.borderColor = UIColor.white.cgColor
        }
        if isSelected {
            colorView.layer.borderWidth = 5.0
        }else{
            colorView.layer.borderWidth = 0
        }
    }
}
