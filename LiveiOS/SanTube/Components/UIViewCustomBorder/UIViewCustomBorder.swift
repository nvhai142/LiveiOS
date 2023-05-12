//
//  UIViewCustomBorder.swift
//  SanTube
//
//  Created by Dai Pham on 3/9/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import UIKit

enum UIViewCustomBorderType {
    case left
    case right
    case top
    case bottom
}

class UIViewCustomBorder:UIView {
    var type: [UIViewCustomBorderType] = [.left, .right, .bottom, .top]
    var color:String = "0xFCCE2F"
    var lineWidth:CGFloat = 2
    init(frame: CGRect,_ type:[UIViewCustomBorderType],_ color:String? = nil,_ lineWidth:CGFloat? = 2) {
        super.init(frame: frame)
        self.type = type
        if let cl = color {
            self.color = cl
        }
        if let cl = lineWidth {
            self.lineWidth = cl
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = UIColor.clear
        layer.masksToBounds = false
        
        if self.bounds.width <= 0 || self.bounds.height <= 0 {
            return
        }
        if let subs = layer.sublayers {
            for la in subs.reversed() {
                if la .isKind(of: CAShapeLayer.self) {
                    la.removeFromSuperlayer()
                }
            }
        }
        
        for t in self.type {
            if t == .left {
                let leftPath:UIBezierPath = UIBezierPath()
                leftPath.move(to: CGPoint(x: 0, y: 0 ))
                leftPath.addLine(to: CGPoint(x: 0, y: self.bounds.maxY))
                
                let leftLayer:CAShapeLayer = CAShapeLayer()
                leftLayer.lineWidth = lineWidth
                leftLayer.position = CGPoint(x:0,y:0)
                leftLayer.path = leftPath.cgPath
                leftLayer.strokeColor = UIColor(hex:self.color).cgColor
                leftLayer.fillColor = nil;
                self.layer.addSublayer(leftLayer)
            }
            
            if t == .right {
                let leftPath:UIBezierPath = UIBezierPath()
                leftPath.move(to: CGPoint(x: self.bounds.maxX, y: 0 ))
                leftPath.addLine(to: CGPoint(x: self.bounds.maxX, y: self.bounds.maxY))
                
                let leftLayer:CAShapeLayer = CAShapeLayer()
                leftLayer.lineWidth = lineWidth
                leftLayer.position = CGPoint(x:0,y:0)
                leftLayer.path = leftPath.cgPath
                leftLayer.strokeColor = UIColor(hex:self.color).cgColor
                leftLayer.fillColor = nil;
                self.layer.addSublayer(leftLayer)
            }
            
            if t == .bottom {
                let bottomPath:UIBezierPath = UIBezierPath()
                bottomPath.move(to: CGPoint(x: 0, y: self.bounds.maxY))
                bottomPath.addLine(to: CGPoint(x: self.bounds.maxX, y: self.bounds.maxY))
                
                let BottomLayer:CAShapeLayer = CAShapeLayer()
                BottomLayer.lineWidth = lineWidth
                BottomLayer.position = CGPoint(x:0,y:0)
                BottomLayer.path = bottomPath.cgPath
                BottomLayer.strokeColor = UIColor(hex:self.color).cgColor
                BottomLayer.fillColor = nil;
                self.layer.addSublayer(BottomLayer)
            }
            
            if t == .top {
                let bottomPath:UIBezierPath = UIBezierPath()
                bottomPath.move(to: CGPoint(x: 0, y: 0))
                bottomPath.addLine(to: CGPoint(x: self.bounds.maxX, y: 0))
                
                let BottomLayer:CAShapeLayer = CAShapeLayer()
                BottomLayer.lineWidth = lineWidth
                BottomLayer.position = CGPoint(x:0,y:0)
                BottomLayer.path = bottomPath.cgPath
                BottomLayer.strokeColor = UIColor(hex:self.color).cgColor
                BottomLayer.fillColor = nil;
                self.layer.addSublayer(BottomLayer)
            }
        }
    }
}
