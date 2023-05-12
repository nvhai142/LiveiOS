//
//  QuickViewController.swift
//  SanTube
//
//  Created by Dai Pham on 12/13/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

let PERCENT_HEIGHT_ITEM_QUICK = CGFloat(100)

class QuickViewController: BasePresentController {

    // MARK: - outlet
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackContainer: UIStackView!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var iconScrollUp: UIImageView!
    @IBOutlet weak var iconScrollDown: UIImageView!
    
    // MARK: - properties
    var minimizeVideo:PresentVideoController!
    var listStream:[Stream] = []
    var listShow:[Stream] = []
    var currentItemIndex:Int = -1
    var currentScrollPage:CGFloat = -1
    var checkShouldReloadItemForNextPage:Bool = true
    var identifier:String = ""
    var statusBar: UIStatusBarStyle = .default
    
    var isStopDragingScrollView:Bool = true
    var currentOffsetScrolLView:CGFloat = 0
    
    // remember icon scroll isHidden
    var remeberIconScrollUpHidden:Bool = false
    var remeberIconScrollDownHidden:Bool = false
    
    // MARK: - closures
    var onMinimize:(()->Void)?
    var onFullScreen:(()->Void)?
    var onCloseQuickView:(()->Void)?
    var needLoadMore:(()->Void)?
    var onGotoDetailStream:((Stream,PresentVideoController,IJKFFMoviePlayerController?)->Void)?
    var onDidDragToHideQuickView:((CGFloat,Bool)->Bool)?
    var onShouldDidDragToHideQuickView:((CGFloat)->Bool)?
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configView()
        createListStream()
        listernEvent()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    deinit {
        print("RESET QUICK VIEW")
        self.listStream.removeAll()
        scrollView.isScrollEnabled = true
        currentItemIndex = -1
        _ = self.childViewControllers.map({
            if $0.isKind(of: PresentVideoController.self) {
                ($0 as! PresentVideoController).stopPlay()
                ($0 as! PresentVideoController).type = .quick
//                $0.view.removeFromSuperview()
//                $0.removeFromParentViewController()
            }
        })
    }
    
    // MARK: - listern event
    func listernEvent() {
        iconScrollUp.addEvent {[weak self] in
            guard let _self = self else {return}
            _self.view.layoutIfNeeded()
            _self.scrollView.setContentOffset(CGPoint(x: 0,y: 0), animated: true)
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: {timer in
                timer.invalidate()
                _self.resortListStream(currentPage: 0)
            })
        }
        
        iconScrollDown.addEvent {[weak self] in
            guard let _self = self else {return}
            _self.view.layoutIfNeeded()            
            _self.scrollView.setContentOffset(CGPoint(x: 0,y:_self.scrollView.contentOffset.y + _self.scrollView.frame.size.height), animated: true)
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: {timer in
                timer.invalidate()
                _self.resortListStream(currentPage: 2)
            })
        }
    }
    
    // MARK: - interface
    func load(_ list:[Stream],start from:Stream,_ isAppend:Bool = true) {
        
        if self.childViewControllers.count == 0 {
            configView()
            createListStream()
        }
        
        if !isAppend {
            listStream = list
        } else {
            listStream.append(contentsOf: list)
            return
        }
        
        var index = 0
        for item in listStream {
            if item.id == from.id {
                currentItemIndex = index
                break
            }
            index += 1
        }
        
        resortListStream(currentPage:currentItemIndex == 0 ? 0 : 1)
    }
    
    func releaseQuickview() {
        self.onCloseQuickView?()
        self.listStream.removeAll()
        guard let _ = scrollView else { return }
        scrollView.isScrollEnabled = true
        currentItemIndex = -1
        _ = self.childViewControllers.map({
            if $0.isKind(of: PresentVideoController.self) {
                ($0 as! PresentVideoController).stopPlay()
                ($0 as! PresentVideoController).type = .quick
//                $0.view.removeFromSuperview()
//                $0.removeFromParentViewController()
            }
        })
        self.view.layoutIfNeeded()
    }
    
    // MARK: - private
    func resortListStream(currentPage:Int) {
        if currentPage == 0 {
            currentItemIndex -= 1
            if currentItemIndex < 0 {
                currentItemIndex = 0
            }
        } else if currentPage == 2 {
            currentItemIndex += 1
            if currentItemIndex > listStream.count - 1{
                currentItemIndex = listStream.count - 1
                return
            }
        }
        
        if currentItemIndex == 0 {
            currentItemIndex = currentPage
        }
        
        var start = currentItemIndex - 1
        var end = currentItemIndex + 2
        
        if start < 0 {
            start = 0
        }
        
        if end > listStream.count {
            end = listStream.count
        }
        
        if end >= listStream.count - 2 {
            self.needLoadMore?()
        }
        
        print("\(start)-> \(currentItemIndex)-> \(end)")
        
        // get stream need show
        listShow = []
        for i in start..<end {
            listShow.append(listStream[i])
        }
        
        // load new stream for list
        var i = 0
        for item in listShow {
            if let vc = self.childViewControllers[i] as? PresentVideoController {
                vc.stream = item
                print("set stream")
                vc.stopPlay()
                if i == 0 && currentItemIndex == 0 || currentItemIndex == listStream.count - 1{
                    vc.playStream()
                } else if currentItemIndex > 0 && currentItemIndex < listStream.count - 1 && i == 1{
                    vc.playStream()
                }
            }
            i += 1
        }
        
        if currentItemIndex == 0 {
            iconScrollUp.isHidden = true
        } else {
            iconScrollUp.isHidden = false
        }
        
        if currentItemIndex == listStream.count - 1{
            iconScrollDown.isHidden = true
        } else {
            iconScrollDown.isHidden = false
        }
        
        let view1 = stackContainer.arrangedSubviews[1]
        view1.isHidden = listShow.count == 1
        
        if stackContainer.arrangedSubviews.count > 2 {
            let view2 = stackContainer.arrangedSubviews[2]
            view2.isHidden = listShow.count < 3
        }
        
        // only scroll to mid item when current item > 0 and < listStream.count
        if (currentItemIndex > 0 && currentItemIndex < listStream.count) {
            self.view.layoutIfNeeded()
            scrollView.setContentOffset(CGPoint(x: 0,y: scrollView.frame.size.height * PERCENT_HEIGHT_ITEM_QUICK / 100), animated: false)
        }
        
        currentScrollPage = scrollView.contentOffset.y
    }
    
    func createListStream() {
        for i in 0..<3 {
            let vc = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
            self.addChildViewController(vc)
            stackContainer.addArrangedSubview(vc.view)
            vc.view.tag = i + 1
            vc.type = .quick
            
            // set constraint height for this subview
            vc.view.translatesAutoresizingMaskIntoConstraints = false
            let height = vc.view.heightAnchor.constraint(equalTo: scrollView.heightAnchor, multiplier: PERCENT_HEIGHT_ITEM_QUICK/100)
            height.priority = 755
            scrollView.addConstraint(height)
            
            // listern event from stream
            vc.onGotoDetailStream = {[weak self] stream, present, playerStream in
                guard let _self = self else {return}
                _self.onGotoDetailStream?(stream,present, playerStream)
            }
            
            vc.onPlayStream = {[weak self] stream, vc in
                guard let _self = self else {return}
                _self.playStream(stream: stream, vc: vc)
            }
            vc.onMinimize = {[weak self] stream, vc in
                guard let _self = self else {return}
                _self.minimizeQuickView(stream: stream,vc: vc)
            }
            vc.onRestoreScreen = {[weak self] stream, vc in
                guard let _self = self else {return}
                _self.fullScreenQuickView(stream: stream,vc)
            }
            vc.onVideoFullScreen = {[weak self] isFullScreen in
                guard let _self = self else {return}
                for item in _self.childViewControllers {
                    if let vcTemp = item as? PresentVideoController {
                        vcTemp.type = isFullScreen ? .full : .quick
                    }
                }
            }
            vc.onTurnOffStream = {[weak self] stream, present in
                guard let _self = self else {return}
                
                // first remove parent controller and superview
                present.view.removeFromSuperview()
                present.removeFromParentViewController()
                
                // remove current on this view
                var listChildControlers:[PresentVideoController] = []
                _ = _self.childViewControllers.map {
                    if let vc = $0 as? PresentVideoController {
                        vc.view.removeFromSuperview()
                        vc.removeFromParentViewController()
                        listChildControlers.append(vc)
                    }
                }
                
                // add controller vs subview into array and sort by tag
                listChildControlers.append(present)
                listChildControlers = listChildControlers.sorted{$0.view.tag < $1.view.tag}
                
                // readd into view
                
                for vc in listChildControlers {
                    _self.addChildViewController(vc)
                    _self.stackContainer.addArrangedSubview(vc.view)
//                    vc.type = .quick
                    vc.view.translatesAutoresizingMaskIntoConstraints = false
                    let height = vc.view.heightAnchor.constraint(equalTo: _self.scrollView.heightAnchor, multiplier: PERCENT_HEIGHT_ITEM_QUICK/100)
                    height.priority = 755
                    _self.scrollView.addConstraint(height)
                }
                
                _self.view.layoutIfNeeded()
                
                _self.scrollView.setContentOffset(present.view.getWindowTop(to: _self.stackContainer), animated: false)
                
                // avoid get resort child controllers if not back from detail
                present.isBackFromDetail = false
                present.type = .quick
                present.didMove(toParentViewController: _self)
            }
        }
    }
    
    func loadFullScreen(stream:Stream,vc:PresentVideoController) {
        
        Timer.scheduledTimer(withTimeInterval: 0, repeats: false, block: {[weak self] timer in
            timer.invalidate()
            guard let _self = self else {return}
            _self.scrollView.isScrollEnabled = true
            _self.scrollView.setContentOffset(vc.view.getWindowTop(to: vc.view.superview!), animated: false)
        })
        
        self.onFullScreen?()
        
        for item in self.childViewControllers {
            if let vcTemp = item as? PresentVideoController {
                vcTemp.type = .quick
            }
        }
        
        self.view.layoutIfNeeded()
    }
    
    // MARK: - event
    @IBAction func close(_ sender: Any) {
        releaseQuickview()
    }
    
    // MARK: - private
    func playStream(stream:Stream, vc:PresentVideoController) {
        var index = 0
        for item in self.childViewControllers {
            if let vcTemp = item as? PresentVideoController {
                if vcTemp.isEqual(vc) {
//                    vcTemp.playStream(stream: stream)
                } else {
                    vcTemp.stopPlay()
                }
                index += 1
            }
        }
    }
    
    func configView() {
        // setup video minimize
        scrollView.delegate = self
        
        iconScrollUp.image = #imageLiteral(resourceName: "arrow_up_white_48").resizeImageWith(newSize: CGSize(width: 15, height: 15)).withRenderingMode(.alwaysTemplate)
        iconScrollUp.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5)
        
        iconScrollDown.image = #imageLiteral(resourceName: "arrow_down_white_48").resizeImageWith(newSize: CGSize(width: 15, height: 15)).withRenderingMode(.alwaysTemplate)
        iconScrollDown.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5)
        
        startAnimations()
    }
    
    func startAnimations() {
        let options: UIViewKeyframeAnimationOptions = [.curveEaseInOut, .repeat,.allowUserInteraction]
        UIView.animateKeyframes(withDuration: 1, delay: 0, options: options, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5, animations: {
                
                self.iconScrollUp.alpha = 0.6
                self.iconScrollUp.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                self.iconScrollUp.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                self.iconScrollUp.transform = CGAffineTransform(translationX: 0, y: 2)
                
                
                self.iconScrollDown.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                self.iconScrollDown.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                self.iconScrollDown.transform = CGAffineTransform(translationX: 0, y: -2)
                self.iconScrollDown.alpha = 0.6
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5, animations: {
                self.iconScrollUp.transform = CGAffineTransform.identity
                self.iconScrollUp.alpha = 0.5
                
                self.iconScrollDown.transform = CGAffineTransform.identity
                self.iconScrollDown.alpha = 0.5
            })
            
        }, completion: nil)
    }
}

// handle minimize video
extension QuickViewController {
    
    func minimizeQuickView(stream:Stream,vc:PresentVideoController) {
        checkShouldReloadItemForNextPage = false
        
        self.onMinimize?()
        
        remeberIconScrollUpHidden = iconScrollUp.isHidden
        remeberIconScrollDownHidden = iconScrollDown.isHidden
        iconScrollDown.isHidden = true
        iconScrollUp.isHidden = true
        for item in self.childViewControllers {
            if let vcTemp = item as? PresentVideoController {
                vcTemp.type = .minimize
                vcTemp.forceOpenPlayBackControl = false
            }
        }
        
//        self.view.layoutIfNeeded()
        
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: {[weak self] timer in
            timer.invalidate()
            guard let _self = self else {return}
            _self.scrollView.setContentOffset(vc.view.getWindowTop(to: vc.view.superview!), animated: false)
            _self.scrollView.isScrollEnabled = false
        })
        
        btnClose.isHidden = true
    }
    
    func fullScreenQuickView(stream:Stream,_ vc:PresentVideoController? = nil) {
        
        iconScrollDown.isHidden = remeberIconScrollDownHidden
        iconScrollUp.isHidden = remeberIconScrollUpHidden
        
        self.scrollView.isHidden = false
        guard let v = vc else { return}
        self.loadFullScreen(stream: stream, vc: v)
        checkShouldReloadItemForNextPage = true
        btnClose.isHidden = false
    }
}

// MARK: - handle scroll index
extension QuickViewController:UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        if self.view.superview!.isHidden {return}
        
        scrollView.isUserInteractionEnabled = true
        var offsetY = scrollView.contentOffset.y
        if offsetY < 0 || (offsetY > 0 && offsetY < scrollView.frame.size.height){
            self.scrollView.setContentOffset(CGPoint.zero, animated: true)
            offsetY = 0
        }
        var page = ((offsetY * PERCENT_HEIGHT_ITEM_QUICK)/100) / ((scrollView.frame.size.height * PERCENT_HEIGHT_ITEM_QUICK)/100)
        
        if page < 0{
            page = 0
        }
        
        print(page)
        if currentScrollPage != offsetY && checkShouldReloadItemForNextPage {
            resortListStream(currentPage: Int(page))
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        isStopDragingScrollView = false
        currentOffsetScrolLView = 0
        let page = ((scrollView.contentOffset.y * PERCENT_HEIGHT_ITEM_QUICK)/100) / ((scrollView.frame.size.height * PERCENT_HEIGHT_ITEM_QUICK)/100)
        if page > 0 {
            isStopDragingScrollView = true
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isStopDragingScrollView {return}
        let tranlation = scrollView.panGestureRecognizer.translation(in: scrollView.superview!)
        let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView.superview!)
        if !self.onShouldDidDragToHideQuickView!(tranlation.y) {
            return
        }
        let step = 5*(velocity.y/500)
        if tranlation.y > 0 {
            if currentOffsetScrolLView < tranlation.y {
                _ = self.onDidDragToHideQuickView?(-step,isStopDragingScrollView)
            } else {
                _ = self.onDidDragToHideQuickView?(step < 10 ? 10 : step,isStopDragingScrollView)
            }
        } else {
            if currentOffsetScrolLView > tranlation.y {
                _ = self.onDidDragToHideQuickView?(-step,isStopDragingScrollView)
            } else {
                _ = self.onDidDragToHideQuickView?(step,isStopDragingScrollView)
            }
        }
        currentOffsetScrolLView = tranlation.y
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        if isStopDragingScrollView {
            return
        }
        isStopDragingScrollView = true
        if self.onDidDragToHideQuickView!(0,isStopDragingScrollView) {
            self.scrollView.setContentOffset(CGPoint.zero, animated: true)
        }
    }
}
