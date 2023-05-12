//
//  BallonGameController.swift
//  SanTube
//
//  Created by Dai Pham on 12/25/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

let WIDTH_BUBBLE:CGFloat = 50
let TIME_LIFE_BUBBLE:CFTimeInterval = 10

class BubbleGameController: UIViewController {

    // MARK: - properties
    var timerCreateBubble:Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    deinit {
        timerCreateBubble?.invalidate()
    }
    
    // MARK: - interface
    func startGame() {
        timerCreateBubble = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            self.createBubble()
        }
    }
    
    // MARK: - event
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count == 1 {
            for touch in touches {
                guard let _ = touch.view else {return}
                var point = touch.location(in: touch.view!)
                point = touch.view!.convert(point, to: nil)
                
                var layer = view.layer.presentation()?.hitTest(point)
                layer = layer?.model()
                if let view = layer?.value(forKey: "Bubble") as? UIImageView{
                    print(view.tag)
                    UIView.transition(with: view, duration: 0.1, options: [.transitionCrossDissolve,.allowUserInteraction], animations: {
                        view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                    }, completion: { (finished) in
                        print("\(view.tag) remove")
                        view.removeFromSuperview()
                    })
                }
            }
        }
    }
    
    // MARK: - private
    func createBubble() {
        let bubble = UIImageView(image: #imageLiteral(resourceName: "placeholder").tint(with: randomColor()))
        bubble.contentMode = .scaleAspectFit
        bubble.clipsToBounds = true
        bubble.frame = CGRect(origin: CGPoint(x: randomFloat(from: WIDTH_BUBBLE, to: UIScreen.main.bounds.maxX - WIDTH_BUBBLE), y: UIScreen.main.bounds.maxY), size: CGSize(width: WIDTH_BUBBLE, height: WIDTH_BUBBLE))
        view.addSubview(bubble)
        
        // get the starting X for bubble
        let bubleX = randomFloat(from: WIDTH_BUBBLE*2, to: UIScreen.main.bounds.maxX - WIDTH_BUBBLE*2)
        bubble.tag = Int(bubleX)
        // store bubble to layer, use get bubble
        bubble.layer.setValue(bubble, forKey: "Bubble")
        
        let zigzagPath = UIBezierPath()
        let oX = bubleX
        let oY = bubble.frame.origin.y
        let eX = oX
        var eY = oY
        eY = 0 // end of Y
        let t = randomFloat(from: WIDTH_BUBBLE*2, to: UIScreen.main.bounds.maxX - WIDTH_BUBBLE*2)
        var cp1 = CGPoint(x: oX - t, y: (oY + eY)/2)
        var cp2 = CGPoint(x: oX + t, y: cp1.y)
        
        // random switch up the control points so that the bubble
        // swings right or left at random
        let r = arc4random() % 2
        if r == 1 {
            let temp = cp1
            cp1 = cp2
            cp2 = temp
        }
        
        // starting point of the line for bubble
        zigzagPath.move(to: CGPoint(x: oX, y: oY))
        // add the end points and the control points
        zigzagPath.addCurve(to: CGPoint(x: eX, y: eY), controlPoint1: cp1, controlPoint2: cp2)
        
        CATransaction.begin()
        
        // if end transaction => remove buble
        CATransaction.setCompletionBlock {
            UIView.transition(with: bubble, duration: 0.1, options: [.transitionCrossDissolve,.allowUserInteraction], animations: {
                bubble.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            }, completion: { (finished) in
                print("Buble remove")
                bubble.removeFromSuperview()
            })
        }
        
        let pathAnimation = CAKeyframeAnimation.init(keyPath: "position")
        pathAnimation.duration = TIME_LIFE_BUBBLE
        pathAnimation.path = zigzagPath.cgPath
        pathAnimation.fillMode = kCAFillModeForwards
        pathAnimation.isRemovedOnCompletion = false
        
        bubble.layer.add(pathAnimation, forKey: "movingAnimation")
        CATransaction.commit()
    }
    
    func randomFloat(from:CGFloat, to:CGFloat) ->CGFloat {
        return CGFloat(arc4random_uniform(UInt32(to - from))) + from
    }
    
    func randomColor() -> UIColor {
        return UIColor(red:   CGFloat(arc4random()) / CGFloat(UInt32.max),
                       green: CGFloat(arc4random()) / CGFloat(UInt32.max),
                       blue:  CGFloat(arc4random()) / CGFloat(UInt32.max),
                       alpha: 1.0)
    }
}
