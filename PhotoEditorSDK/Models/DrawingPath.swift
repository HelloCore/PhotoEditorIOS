//
//  DrawingPath.swift
//  PhotoEditorSDK
//
//  Created by Akkharawat Chayapiwat on 8/6/18.
//  Copyright © 2018 Akkharawat Chayapiwat. All rights reserved.
//

import Foundation

class DrawingPath {
    
    var color: CGColor
    var lineWidth: CGFloat
    var path: CGMutablePath
    
    var lineCap: CGLineCap
    var blendMode: CGBlendMode
    
    var isEmpty: Bool {
        return self.path.isEmpty
    }
    
    init(color: CGColor, lineWidth: CGFloat, path: CGMutablePath = CGMutablePath(), lineCap: CGLineCap = CGLineCap.round, blendMode: CGBlendMode = CGBlendMode.normal) {
        self.color = color
        self.lineWidth = lineWidth
        self.path = path
        self.lineCap = lineCap
        self.blendMode = blendMode        
    }
    
    func addLine(from fromPoint: CGPoint, to toPoint: CGPoint) {
        self.path.move(to: fromPoint)
        self.path.addLine(to: toPoint)
    }
    
    func drawInContext(_ context: CGContext) {
        context.addPath(self.path)
        
        context.setLineCap(self.lineCap)
        context.setLineWidth(self.lineWidth)
        context.setStrokeColor(self.color)
        context.setBlendMode(self.blendMode)
        
        context.strokePath()
    }
    
    
}
