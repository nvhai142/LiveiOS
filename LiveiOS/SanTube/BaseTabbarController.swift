//
//  BaseTabbarController.swift
//  SanTube
//
//  Created by Dai Pham on 1/15/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class BaseTabbarController: UITabBarController {

    // MARK: - api
    func prepareToOpenStream() {
        
        guard let window = self.view.window else { return }
        
        configQuickView()
        
        let quickViewController = window.quickViewcontroller()
        quickViewController.releaseQuickview()
        if vwQuickView.transform.isIdentity {
            vwQuickView.transform = .identity
        }
    }
    
    func gotoStream(streamID:String) {
        UserDefaults.standard.removeObject(forKey: "App::StreamID")
        UserDefaults.standard.synchronize()
        Server.shared.getStream(streamId: streamID) {[weak self] stream, err in
            guard let _self = self,let streamLocal = stream else {return}
            if streamLocal.status == AppConfig.status.stream.streaming() {
                let present = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
                let vc = StreamViewController(nibName: "StreamViewController", bundle: Bundle.main)
                vc.streamVideoController = present
                vc.stream = streamLocal
                _self.present(vc, animated: false)
            }
        }
    }
    
    // MARK: - mark drag
    var bottom:NSLayoutConstraint?
    var trailing:NSLayoutConstraint?
    var beginDragYPoint:CGFloat = 0
    var beginDragXPoint:CGFloat = 0
    
    func drag(_ gesture:UIPanGestureRecognizer) {
        guard isMinimize == true else {return}
        guard let superview = vwQuickView.superview, let window = self.view.window else { return }
        let translation = gesture.translation(in: self.view.window)
        switch gesture.state {
        case .began:
            for constraint in superview.constraints {
                if constraint.firstAttribute == .bottom && constraint.firstItem!.isEqual(vwQuickView) {
                    bottom = constraint
                }
                
                if constraint.firstAttribute == .trailing && constraint.firstItem!.isEqual(vwQuickView) {
                    trailing = constraint
                }
            }
            beginDragXPoint = translation.x
            beginDragYPoint = translation.y
        case .ended:
            beginDragXPoint = translation.x
            beginDragYPoint = translation.y
            guard let tr = trailing, let bo = bottom else {return}
            let halfWidth = self.view.window!.frame.size.width/2
            let halfHeight = self.view.window!.frame.size.height/2
            window.layoutIfNeeded()
            if tr.constant - 40 < -halfWidth && tr.constant - 40 >  -halfWidth*2{
                tr.constant = -halfWidth*2 + 10 + 80
            } else if tr.constant - 40 <  -halfWidth*2  || tr.constant - 40 > -5 {
                self.isMinimize = false
                self.closeQuickView()
                return
            } else {
                tr.constant = -5
            }
            
            if bo.constant - (80 * 1.774)/2 > -halfHeight && bo.constant - (80 * 1.774)/2 <  -20 {
                bo.constant = -55
            } else if bo.constant - (80 * 1.774)/2 <  -halfHeight*2  || bo.constant - (80 * 1.774)/2 > -20{
                self.isMinimize = false
                self.closeQuickView()
                return
            } else {
                bo.constant = -halfHeight*2 + 26 + (80 * 1.774)
            }
            window.setNeedsLayout()
            UIView.animate(withDuration: 0.2, animations: {
                window.layoutIfNeeded()
            })
        case .changed:
            trailing?.constant += translation.x - beginDragXPoint
            bottom?.constant += translation.y - beginDragYPoint
            window.setNeedsLayout()
            beginDragXPoint = translation.x
            beginDragYPoint = translation.y
        case .possible:
            break
        case .cancelled:
            #if DEBUG
                print("canceld")
            #endif
        case .failed:
            #if DEBUG
                print("failed")
            #endif
        }
    }
    
    // MARK: - private
    var timerCheckWindowExist:Timer?
    func configQuickView() {
        if vwQuickView == nil {return}
        guard let _ = self.view.window else { return }
        UIApplication.shared.keyWindow?.bringSubview(toFront: vwQuickView)
        // setup quick video
        let quickViewController = self.view.window!.quickViewcontroller()
        
                quickViewController.onGotoDetailStream = nil
                quickViewController.onDissmiss = nil
                quickViewController.onMinimize = nil
                quickViewController.onFullScreen = nil
                quickViewController.onCloseQuickView = nil
                quickViewController.needLoadMore = nil
        
        if vwQuickView.subviews.count == 0 {
            vwQuickView.addSubview(quickViewController.view)
            quickViewController.didMove(toParentViewController: nil)
            quickViewController.view.translatesAutoresizingMaskIntoConstraints = false
            quickViewController.view.topAnchor.constraint(equalTo: vwQuickView.topAnchor).isActive = true
            quickViewController.view.leadingAnchor.constraint(equalTo: vwQuickView.leadingAnchor).isActive = true
            quickViewController.view.bottomAnchor.constraint(equalTo: vwQuickView.bottomAnchor).isActive = true
            quickViewController.view.trailingAnchor.constraint(equalTo: vwQuickView.trailingAnchor).isActive = true
        }
        
        quickViewController.onGotoDetailStream = {[weak self] stream, present, playerStream in
            guard let _self = self else {return}
            if let window = _self.view.window {
                let quickViewController = window.quickViewcontroller()
                quickViewController.scrollView.delegate = nil
            }
            // remove comment when turn on quickview after back from detail page
//            _self.isGotoDetail = true
            _self.vwQuickView.transform = CGAffineTransform(translationX: 0, y: 5000)
            if stream.status == AppConfig.status.stream.streaming() {
                let vc = StreamViewController(nibName: "StreamViewController", bundle: Bundle.main)
                vc.streamVideoController = present
                vc.player = playerStream
                vc.stream = stream
                vc.onDissmiss = {[weak _self] in
                    guard let __self = _self else {return}
                    
                    // because window only appear when previous view diddisappear, so we have to timer to check window exist
                    __self.timerCheckWindowExist = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: {[weak __self] timer in
                        print("TIMER CHECKING WINDOW IS EXIST AFTER LIVESTREAM STOP")
                        guard let ___self = __self, let window = ___self.view.window else {return}
                        ___self.timerCheckWindowExist?.invalidate()
                        ___self.timerCheckWindowExist = nil
                        window.quickViewcontroller().releaseQuickview()
                    })
                }
                _self.present(vc, animated: false)
            } else {
                let vc = DetailStreamController(nibName: "DetailStreamController", bundle: Bundle.main)
                vc.stream = stream
                vc.streamVideoController = present
                vc.onGotoLiveStream = {[weak _self] str in
                    guard let __self = _self else {return}
                    let present = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
                    let vc = StreamViewController(nibName: "StreamViewController", bundle: Bundle.main)
                    vc.streamVideoController = present
                    vc.stream = str
                    __self.present(vc, animated: false)
                    vc.onGotoStreamDetail = {[weak __self] stream1 in
                        guard let ___self = __self else {return}
                        let present1 = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
                        let vc1 = DetailStreamController(nibName: "DetailStreamController", bundle: Bundle.main)
                        vc1.streamVideoController = present1
                        vc1.stream = stream1
                        vc1.onGotoLiveStream = {[weak ___self] str in
                            guard let ____self = ___self else {return}
                            let present2 = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
                            let vc2 = StreamViewController(nibName: "StreamViewController", bundle: Bundle.main)
                            vc2.streamVideoController = present2
                            vc2.stream = str
                            ____self.present(vc2, animated: false)
                        }
                        ___self.present(vc1, animated: true)
                    }
                }
                // remove comment when turn on quickview after back from detail page
//                vc.onDissmiss = {[weak _self] in
//                    guard let __self = _self else {return}
//                    if let window = __self.view.window {
//                        let quickViewController = window.quickViewcontroller()
//                        quickViewController.scrollView.delegate = quickViewController
//                    }
//                }
                
                _self.present(vc, animated: true)
            }
        }
        
        quickViewController.onDissmiss = {[weak self] in
            guard let _self = self else {return}
            _self.isMinimize = false
            _self.vwQuickView.transform = CGAffineTransform(translationX: 0, y: 5000)
        }
        
        quickViewController.onMinimize = {[weak self] in
            guard let _self = self else {return}
            _self.isMinimize = true
            _self.minimizeQuickView()
        }
        
        quickViewController.onFullScreen = {[weak self] in
            guard let _self = self else {return}
            _self.isMinimize = false
            _self.fullScreenView()
        }
        
        quickViewController.onCloseQuickView = {[weak self] in
            guard let _self = self else {return}
            _self.isMinimize = false
            _self.closeQuickView()
        }
        
        quickViewController.onDidDragToHideQuickView = {[weak self] offsetY, isStop in
            
            guard let _self = self else {return false}
            guard let window = _self.view.window else { return false}
            guard _self.isMinimize == false else {return false}
            let quickViewController = window.quickViewcontroller()
            if isStop {
                let y = _self.moveY
                _self.moveY = 0
                if y > UIScreen.main.bounds.size.height*20/100 {
                    UIView.animate(withDuration: 0.5, animations: {
//                        quickViewController.view.frame = CGRect(origin: CGPoint(x: 0, y: UIScreen.main.bounds.height), size: quickViewController.view.frame.size)
                        quickViewController.view.transform = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height)
                    }, completion: {isFinished in
                        _self.isMinimize = false
                        _self.closeQuickView()
                    })
                    return false
                } else {
                    UIView.animate(withDuration: 0.3, animations: {
//                        quickViewController.view.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: quickViewController.view.frame.size)
                        quickViewController.view.transform = .identity
                    }, completion: nil)
                }
                return true
            } else {
                _self.moveY -= offsetY
                if _self.moveY < 0 {
                    _self.moveY = 0
                }
//                quickViewController.view.frame = CGRect(origin: CGPoint(x: 0, y: _self.moveY), size: quickViewController.view.frame.size)
                quickViewController.view.transform = CGAffineTransform(translationX: 0, y: _self.moveY)
                return false
            }
        }
        
        quickViewController.onShouldDidDragToHideQuickView = {[weak self] currentOffset in
            guard let _self = self else {return false}
            guard let window = _self.view.window else { return false}
            let quickViewController = window.quickViewcontroller()
            return (quickViewController.view.frame.origin.y >= 0 && _self.moveY >= 0) || currentOffset > 0
        }
    }
    
    func closeQuickView() {
        if vwQuickView == nil {return}
        fullScreenView()
        self.vwQuickView.transform = CGAffineTransform(translationX: 0, y: 5000)
        guard let window = self.view.window else { return }
        let quickViewController = window.quickViewcontroller()
        quickViewController.view.removeFromSuperview()
        window.setController(vc: nil)
    }
    
    func minimizeQuickView() {
        guard let window = self.view.window else { return}
        window.layoutIfNeeded()
        
        for constraint in vwQuickView.superview!.constraints.reversed() {
            if constraint.firstAttribute == .top && constraint.firstItem.isEqual(vwQuickView){
                vwQuickView.superview!.removeConstraint(constraint)
            }
            if constraint.firstAttribute == .leading && constraint.firstItem.isEqual(vwQuickView){
                vwQuickView.superview!.removeConstraint(constraint)
            }
            
            if constraint.firstAttribute == .trailing && constraint.firstItem!.isEqual(vwQuickView){
                constraint.constant = -5
            }
            
            if constraint.firstAttribute == .bottom && constraint.firstItem!.isEqual(vwQuickView){
                constraint.constant = -55
            }
        }
        
        vwQuickView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        vwQuickView.heightAnchor.constraint(equalTo: vwQuickView.widthAnchor, multiplier: 1.778, constant: 0).isActive = true
        
        UIView.animate(withDuration: 0.3) {[weak self] in
            guard let _self = self else {return}
            _self.view.window!.layoutIfNeeded()
        }
    }
    
    func fullScreenView() {
        guard let window = self.view.window else { return}
        if vwQuickView == nil {return}
        window.layoutIfNeeded()
        
        for constraint in vwQuickView.constraints {
            if constraint.firstAttribute == .width && constraint.firstItem.isEqual(vwQuickView) {
                vwQuickView.removeConstraint(constraint)
            }
            
            if constraint.firstAttribute == .height && constraint.firstItem.isEqual(vwQuickView) {
                vwQuickView.removeConstraint(constraint)
            }
        }
        
        for constraint in vwQuickView.superview!.constraints.reversed() {
            
            if constraint.firstAttribute == .trailing && constraint.firstItem!.isEqual(vwQuickView){
                constraint.constant = 0
            }
            
            if constraint.firstAttribute == .bottom && constraint.firstItem!.isEqual(vwQuickView){
                constraint.constant = 0
            }
        }
        
        vwQuickView.leadingAnchor.constraint(equalTo: vwQuickView.superview!.leadingAnchor).isActive = true
        vwQuickView.topAnchor.constraint(equalTo: vwQuickView.superview!.topAnchor).isActive = true
        
        UIView.animate(withDuration: 0.3) {[weak self] in
            guard let _self = self else {return}
            _self.view.window!.layoutIfNeeded()
        }
    }
    
    // MARK: - notification
    func getNotification(_ notification:NSNotification) {
        if let userInfo = notification.userInfo as? JSON,
            let action = userInfo["action"] as? String {
            if action == "register" {
                let vc = LaunchController(nibName: "LaunchController", bundle: Bundle.main)
                AppConfig.navigation.changeRootControllerTo(viewcontroller: vc)
            } else if action == "login" {
                let vc = HomeController(nibName: "HomeController", bundle: Bundle.main)
                AppConfig.navigation.changeRootControllerTo(viewcontroller: vc)
            } else if action == "logout" {
                let vc = LaunchController(nibName: "LaunchController", bundle: Bundle.main)
                AppConfig.navigation.changeRootControllerTo(viewcontroller: vc)
            }
        }
    }
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(getNotification(_:)), name: NSNotification.Name(rawValue: "App::UserLoginSuccess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getNotification(_:)), name: NSNotification.Name(rawValue: "App::UserLogoutSuccess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getNotification(_:)), name: NSNotification.Name(rawValue: "App::UserRegisterSuccess"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let window = self.view.window {
            for view in window.subviews.reversed() {
                if view.tag == QUICK_VIEW_TAG {
                    vwQuickView = view
                    break
                }
            }
            if vwQuickView == nil {
                vwQuickView = UIView(frame: view.bounds)
                _ = vwQuickView.constraints.reversed().map{vwQuickView.removeConstraint($0)}
                vwQuickView.layer.cornerRadius = 2
                vwQuickView.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
                vwQuickView.layer.shadowOffset = CGSize(width:0.5, height:4.0)
                vwQuickView.layer.shadowOpacity = 0.5
                vwQuickView.layer.shadowRadius = 5.0
                window.addSubview(vwQuickView)
                vwQuickView.tag = QUICK_VIEW_TAG
                vwQuickView.transform = CGAffineTransform(translationX: 0, y: 5000)
                vwQuickView.backgroundColor = UIColor.clear
                vwQuickView.translatesAutoresizingMaskIntoConstraints = false
                
                vwQuickView.topAnchor.constraint(equalTo: vwQuickView.superview!.topAnchor, constant: 0).isActive = true
                vwQuickView.trailingAnchor.constraint(equalTo: vwQuickView.superview!.trailingAnchor, constant: 0).isActive = true
                vwQuickView.bottomAnchor.constraint(equalTo: vwQuickView.superview!.bottomAnchor, constant: 0).isActive = true
                vwQuickView.leadingAnchor.constraint(equalTo: vwQuickView.superview!.leadingAnchor, constant: 0).isActive = true
                
                dragGesture = UIPanGestureRecognizer(target: self, action: #selector(drag))
                dragGesture?.cancelsTouchesInView = false
                vwQuickView.addGestureRecognizer(dragGesture!)
                vwQuickView.isUserInteractionEnabled = true
            }
        }
        configQuickView()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "App::UserLoginSuccess"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "App::UserLogoutSuccess"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "App::UserRegisterSuccess"), object: nil)
        #if DEBUG
        print("tabbarController dealloc")
        #endif
    }
    
    // MARK: - properties
    var vwQuickView: UIView!
    var isGotoDetail:Bool = false
    var dragGesture:UIPanGestureRecognizer?
    var isMinimize:Bool = false
    var moveY:CGFloat = 0
    var registerControllerPresent:UINavigationController?
}
