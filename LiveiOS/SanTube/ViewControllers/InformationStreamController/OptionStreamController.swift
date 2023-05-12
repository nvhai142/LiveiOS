//
//  OptionStreamController.swift
//  SanTube
//
//  Created by Dai Pham on 1/29/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import UIKit

let OPTION_STREAM_SHARE:Int = 1001
let OPTION_STREAM_REPORT:Int = 1002

class OptionStreamController: BasePresentController {

    // MARK: - api

    // MARK: - event
    func touchButton(_ sender:UIButton) {
        self.onSelect?(sender.tag)
        closeView()
        if sender.tag == OPTION_STREAM_SHARE {
            showWarning()
        }
    }
    
    // MARK: - private
    private func closeView() {
        if isShowWarning {
            self.onDissmiss?()
            self.dismiss(animated: false, completion: nil)
            return
        }
        UIView.animate(withDuration: 0.2, animations: {
            self.containerView.alpha = 0
            self.containerView.transform = CGAffineTransform(translationX: -50, y: 0).concatenating(CGAffineTransform(translationX: self.containerView.frame.size.width, y: 0))
        }, completion: {isDone in
            self.onDissmiss?()
            if !self.isShowWarning {
                self.dismiss(animated: false, completion: nil)
            }
        })
    }
    
    
    var isShowWarning:Bool = false
    private func showWarning() {
        isShowWarning = true
        let label = UILabel(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 10, height: 10)))
        label.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        label.layer.borderColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        label.layer.borderWidth = 1.5
        label.font = UIFont.boldSystemFont(ofSize: fontSize16)
        label.layer.cornerRadius = 50/2
        label.text = "    This function will coming soon.    ".localized().capitalizingFirstLetter()
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        label.heightAnchor.constraint(equalToConstant: 50).isActive = true
        view.bringSubview(toFront: label)
        UIView.animate(withDuration: 3, animations: {
            label.alpha = 0
        }, completion: {isDone in
            self.dismiss(animated: false, completion: nil)
        })
    }
    
    private func configView() {
        
        containerView = UIView(frame: CGRect(origin: startPoint, size: CGSize(width: 100, height: 100)))
        containerView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.6)
        containerView.alpha = 0
        containerView.layer.cornerRadius = 2
        containerView.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        containerView.layer.shadowOffset = CGSize(width:-0.1, height:-0.1)
        containerView.layer.shadowOpacity = 0.5
        containerView.layer.shadowRadius = 5.0
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        let width = containerView.widthAnchor.constraint(equalToConstant: 200)
        let height = containerView.heightAnchor.constraint(equalToConstant: 100)
        width.priority = 10
        height.priority = 10
        containerView.addConstraint(width)
        containerView.addConstraint(height)
        if #available(iOS 11.0, *) {
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: containerView.bottomAnchor,constant:50).isActive = true
        } else {
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor,constant:50).isActive = true
        }
        view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        
        stackControl = UIStackView(frame: CGRect(origin: startPoint, size: CGSize(width: 100, height: 100)))
        stackControl.distribution = .fill
        stackControl.axis = .vertical
        stackControl.spacing = 1
        containerView.addSubview(stackControl)
        stackControl.translatesAutoresizingMaskIntoConstraints = false
        containerView.bottomAnchor.constraint(equalTo: stackControl.bottomAnchor,constant:10).isActive = true
        stackControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        stackControl.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        stackControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        
        
        for item in [["title":"share".localized().capitalizingFirstLetter(),"tag":OPTION_STREAM_SHARE],
                     ["title":"report".localized().capitalizingFirstLetter(),"tag":OPTION_STREAM_REPORT]] {
            let btn = UIButton(type: .custom)
            if let title = item["title"] as? String {
                btn.setTitle(title, for: UIControlState())
            }
            if let tag = item["tag"] as? Int {
                btn.tag = tag
            }
            btn.setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for: .normal)
            btn.setTitleColor(#colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1), for: .highlighted)
            btn.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10)
            btn.addTarget(self, action: #selector(touchButton), for: .touchUpInside)
                        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: fontSize16)
            btn.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
            stackControl.addArrangedSubview(btn)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
    }
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.layoutIfNeeded()
        view.setNeedsDisplay()
        self.containerView.transform = CGAffineTransform(translationX: self.containerView.frame.size.width, y: 0)
        UIView.animate(withDuration: 0.2, animations: {
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        })
        
        view.addEvent {[weak self] in
            guard let _self = self else {return}
            _self.closeView()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.removeEvent()
    }
    
    deinit {
        print("OptionStreamController delloc")
    }
    
    // MARK: - properties
    var stackControl:UIStackView!
    var containerView:UIView!
    var startPoint:CGPoint = CGPoint.zero
    
    // MARK: - closures
    var onSelect:((Int)->Void)?
    
    // MARK: - outlet
}
