//
//  ExtendedNavBarView.swift
//  SanTube
//
//  Created by Dai Pham on 11/22/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

fileprivate let TRAILING:CGFloat = 10

class ExtendedNavBarView: UIView {

    // MARK: - api
    func setTitle(_ string:String? = nil) {
        if let str = string {
            lblTitle.text = str
            lblTitle.isHidden = false
            
            stackTabb.isHidden = true
            vwHightLight.isHidden = true
        }
    }
    
    func scrollDidView(_ scrollView:UIScrollView? = nil) {
        
        let min = TRAILING
        let max = TRAILING + self.lblAllCategories.frame.minX
        
        guard let scrollView = scrollView else {
            let percent:CGFloat = 0
            self.layoutIfNeeded()
            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           options: .allowUserInteraction,
                           animations: {
                            let number = TRAILING + percent * (self.lblAllCategories.frame.minX)/100
                            if number >= min && number <= max {
                                self.constraintLeadingHighlight.constant =  number
                                self.constraintWidthHighlight.constant = self.lblFeatured.frame.width + percent*(self.lblAllCategories.frame.width - self.lblFeatured.frame.width)/100
                            }
                            self.layoutIfNeeded()
            },
                           completion: {isfinised in
                            UIView.animate(withDuration: 0.1, animations: {
                                self.lblFeatured.textColor = self.selectedIndex == 0 ? #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                                self.lblAllCategories.textColor = self.selectedIndex == 1 ? #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                            })
            })
            return
        }
        let percent = scrollView.contentOffset.x*100/scrollView.frame.size.width
        
        self.layoutIfNeeded()
        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       options: .allowUserInteraction,
                       animations: {
                        let number = TRAILING + percent * (self.lblAllCategories.frame.minX)/100
                        if number >= min && number <= max {
                            self.constraintLeadingHighlight.constant =  number
                            self.constraintWidthHighlight.constant = self.lblFeatured.frame.width + percent*(self.lblAllCategories.frame.width - self.lblFeatured.frame.width)/100
                        }
                        self.layoutIfNeeded()
        },
                       completion: {finis in
                        UIView.animate(withDuration: 0.1, animations: {
                            self.lblFeatured.textColor = self.selectedIndex == 0 ? #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                            self.lblAllCategories.textColor = self.selectedIndex == 1 ? #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                        })
        })
    }
    
    func selectIndex(_ index:Int) {
        guard index < 2 else {
            return
        }
        
        selectedIndex = index
        updated()
    }
    
    func removeEnvet() {
        lblAllCategories.removeEvent()
        lblFeatured.removeEvent()
    }
    
    // MARK: - action
    func touchButton(_ sender:UIButton) {
        let vc = InputCodeController(nibName: "InputCodeController", bundle: Bundle.main)
        controller?.tabBarController?.present(vc, animated: false, completion: nil)
        vc.onGotoStream = {[weak self] stream in
            guard let _self = self else {return}
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: {timer in
                print("CHECK PRESENTING IS DEALLOC")
                if _self.controller?.tabBarController?.presentedViewController == nil {
                    timer.invalidate()
                    _self.openStream(stream)
                }
            })
            
        }
    }
    
    private func openStream(_ streamLocal:Stream) {
        
        let present = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
        if streamLocal.status == AppConfig.status.stream.streaming() {
            let vc = StreamViewController(nibName: "StreamViewController", bundle: Bundle.main)
            vc.streamVideoController = present
            vc.stream = streamLocal
            vc.onGotoStreamDetail = {[weak self] stream1 in
                guard let _self = self else {return}
                let present1 = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
                let vc1 = DetailStreamController(nibName: "DetailStreamController", bundle: Bundle.main)
                vc1.streamVideoController = present1
                vc1.stream = stream1
                vc1.onGotoLiveStream = {[weak _self] str in
                    guard let __self = _self else {return}
                    let present2 = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
                    let vc2 = StreamViewController(nibName: "StreamViewController", bundle: Bundle.main)
                    vc2.streamVideoController = present2
                    vc2.stream = str
                    vc2.onGotoStreamDetail = {[weak __self] stream1 in
                        guard let _self = __self else {return}
                        let present1 = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
                        let vc1 = DetailStreamController(nibName: "DetailStreamController", bundle: Bundle.main)
                        vc1.streamVideoController = present1
                        vc1.stream = stream1
                        vc1.onGotoLiveStream = {[weak _self] str in
                            guard let __self = _self else {return}
                            let present2 = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
                            let vc2 = StreamViewController(nibName: "StreamViewController", bundle: Bundle.main)
                            vc2.streamVideoController = present2
                            vc2.stream = str
                            __self.controller?.tabBarController?.present(vc2, animated: false)
                        }
                        _self.controller?.tabBarController?.present(vc1, animated: true)
                    }
                    __self.controller?.tabBarController?.present(vc2, animated: false)
                }
                _self.controller?.tabBarController?.present(vc1, animated: true)
            }
            self.controller?.tabBarController?.present(vc, animated: false)
            return
        }
        
        let vc = DetailStreamController(nibName: "DetailStreamController", bundle: Bundle.main)
        vc.stream = streamLocal
        vc.streamVideoController = present
        vc.onGotoLiveStream = {[weak self] str in
            guard let _self = self else {return}
            let present = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
            let vc = StreamViewController(nibName: "StreamViewController", bundle: Bundle.main)
            vc.streamVideoController = present
            vc.stream = str
            _self.controller?.tabBarController?.present(vc, animated: false)
            vc.onGotoStreamDetail = {[weak _self] stream1 in
                guard let ___self = _self else {return}
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
                    ____self.controller?.tabBarController?.present(vc2, animated: false)
                }
                ___self.controller?.tabBarController?.present(vc1, animated: true)
            }
        }
        self.controller?.tabBarController?.present(vc, animated: true)
    }
    
    private func action() {
        lblFeatured.addEvent {[weak self] in
            guard let _self = self else {return}
            _self.selectedIndex = 0
            _self.updated()
        }
        
        lblAllCategories.addEvent {[weak self] in
            guard let _self = self else {return}
            _self.selectedIndex = 1
            _self.updated()
        }
    }
    
    // MARK: - private
    private func config() {
        
        lblFeatured.text = "featured".localized().capitalizingFirstLetter()
        lblAllCategories.text = "all_categories".localized().capitalizingFirstLetter()
        
        lblFeatured.textColor = UIColor.black
        lblAllCategories.textColor = UIColor.black
        
        lblFeatured.font = UIFont.boldSystemFont(ofSize: fontSize17)
        lblAllCategories.font = UIFont.boldSystemFont(ofSize: fontSize17)
        
        lblFeatured.adjustsFontSizeToFitWidth = true
        lblAllCategories.adjustsFontSizeToFitWidth = true
        
        lblFeatured.textColor = selectedIndex == 0 ? #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        lblAllCategories.textColor = selectedIndex == 1 ? #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        
        btnCode.addTarget(self, action: #selector(touchButton(_:)), for: .touchUpInside)
        btnCode.setImage(#imageLiteral(resourceName: "icon_number_pad").resizeImageWith(newSize: CGSize(width: 15, height: 15*1.31)).tint(with: tintColor), for: UIControlState())
        btnCode.titleLabel?.font = UIFont.boldSystemFont(ofSize: fontSize16)
        btnCode.setTitle("code".localized().capitalizingFirstLetter(), for: UIControlState())
        
        lblTitle.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        lblTitle.font = UIFont.boldSystemFont(ofSize: fontSize17)
    }
    
    private func updated() {
        self.onSelectIndex?(self.selectedIndex)
    }
    
    // MARK: - init
    override func awakeFromNib() {
        super.awakeFromNib()
        
        config()
        action()
        scrollDidView()
    }
    
    // MARK: - closures
    var onSelectIndex:((Int)->Void)?
    
    // MARK: - properties
    var selectedIndex:Int = 0
    var controller:UIViewController?
    
    // MARK: - outlet
    @IBOutlet weak var lblFeatured: UILabel!
    @IBOutlet weak var lblAllCategories: UILabel!
    @IBOutlet weak var btnCode: UIButton!
    @IBOutlet weak var stackTabb: UIStackView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var vwHightLight: UIView!
    
    // MARK: - constraint
    @IBOutlet weak var constraintLeadingHighlight: NSLayoutConstraint!
    @IBOutlet weak var constraintWidthHighlight: NSLayoutConstraint!
}
