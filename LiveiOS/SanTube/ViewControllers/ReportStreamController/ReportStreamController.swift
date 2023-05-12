//
//  ReportStreamController.swift
//  SanTube
//
//  Created by Dai Pham on 3/12/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import UIKit

let OptionsReport = ["dont_like_this".localized().capitalizingFirstLetter(),
                    "self_harm".localized().capitalizingFirstLetter(),
                    "violence".localized().capitalizingFirstLetter(),
                    "sexual_content".localized().capitalizingFirstLetter()]

class ReportStreamController: BasePresentController {

    // MARK: - api
    
    // MARK: - action
    func touchBoutton(_ sender:UIButton) {
        if sender.tag >= OptionsReport.count {return}
        if let content = sender.titleLabel?.text, let user = Account.current, let stream = self.stream {
            // call api report
            sender.startAnimation(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
            disableControl()
            Server.shared.report(streamId: stream.id, userId: user.id, content: content, {[weak self] (errorMS) in
                guard let _self = self else {return}
                _self.enableControl()
                sender.stopAnimation()
                guard let err = errorMS else {
                    _self.closeView(true)
                    return
                }
                Support.notice(title: "notice".localized().capitalizingFirstLetter(),
                               message: err, vc: _self,["ok".localized().uppercased()], nil)
            })
        } else {
            closeView()
        }
    }
    
    func touchGesture(_ sender:UITapGestureRecognizer) {
        closeView()
    }
    
    // MARK: - private
    private func closeView(_ isSendReportSuccess:Bool = false) {
        vwBackGround.removeGestureRecognizer(tapGesture)
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .allowUserInteraction, animations: {
            self.vwContent.transform = CGAffineTransform(translationX: 0, y: 1000)
        }, completion: {done in
            if !done {return}
            if isSendReportSuccess {
                self.onReportSuccess?()
            } else {
                self.onDissmiss?()
            }
            self.dismiss(animated: false, completion: nil)
        })
    }
    
    private func disableControl() {
        _ = stackControls.arrangedSubviews.map{if let btn = $0 as? UIButton {btn.isEnabled = false}}
    }
    
    private func enableControl() {
        _ = stackControls.arrangedSubviews.map{if let btn = $0 as? UIButton {btn.isEnabled = true}}
    }
    
    private func config() {
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(touchGesture(_:)))
        vwBackGround.addGestureRecognizer(tapGesture)
        
        vwContent.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.71).cgColor
        vwContent.layer.shadowOffset = CGSize(width:0.5, height:-3.0)
        vwContent.layer.shadowOpacity = 0.5
        vwContent.layer.shadowRadius = 5.0
        vwContent.layer.cornerRadius = 5
        
        lblTitle.text = "choose_reason_report".localized().capitalizingFirstLetter()
        lblTitle.textColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        lblTitle.font = UIFont.systemFont(ofSize: fontSize16)
        
        for (i,title) in OptionsReport.enumerated() {
            let btn = createButtonsControl(title: title, index: i)
            stackControls.addArrangedSubview(btn)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
        
//        if UI_USER_INTERFACE_IDIOM() != .pad {
//            constrantWidthContent.priority = 999
//        } else {
//            view.removeConstraint(constrantWidthContent)
//        }
    }
    
    private func createButtonsControl(title:String,index:Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = index
        button.setTitle(title, for: UIControlState())
        button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize17)
        button.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
        button.setTitleColor(#colorLiteral(red: 0.9882352941, green: 0.8078431373, blue: 0.1843137255, alpha: 1), for: .highlighted)
        button.addTarget(self, action: #selector(touchBoutton(_:)), for: .touchUpInside)
        return button
    }
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        config()
        
        vwBackGround.alpha = 1
        vwContent.transform = CGAffineTransform(translationX: 0, y: 1000)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        UIView.animate(withDuration: 0.1, delay: 0, options: .allowUserInteraction, animations: {
//            self.vwBackGround.alpha = 1
//        }, completion: {done in
//            if !done {return}
            UIView.animate(withDuration: 0.2, delay: 0, options: .allowUserInteraction, animations: {
                self.vwContent.transform = .identity
            }, completion: nil)
//        })
    }
    
    // MARK: - closures
    var onReportSuccess:(()->Void)?
    
    // MARK: - properties
    var tapGesture:UITapGestureRecognizer!
    var stream:Stream?
    
    
    // MARK: - outlet
    @IBOutlet weak var vwBackGround: UIView!
    @IBOutlet weak var stackControls: UIStackView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var vwContent: UIView!
    
//    @IBOutlet weak var constrantWidthContent: NSLayoutConstraint!
}
