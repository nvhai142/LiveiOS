//
//  OrderDetailController.swift
//  SanTube
//
//  Created by Dai Pham on 1/8/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import UIKit

enum OrderDetailType {
    case view
    case process
}

class OrderDetailController: BasePresentController {

    // MARK: - event
    func actionButton(_ sender:UIButton) {
        if sender.isEqual(btnClose) {
            onDissmiss?()
            self.view.transform = .identity
            UIView.animate(withDuration: 0.2, animations: {
                self.view.alpha = 0
                self.vwContain.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            },completion:{isDone in
                self.dismiss(animated: false, completion: nil)
            })
        }
    }
    
    // MARK: - private
    
    private func setupInformationOrder() {
        guard let order = self.order else {return}
        let title = order.status.localized().capitalizingFirstLetter() + " " + "order".localized() + " \("at".localized()) " + order.updated_at.UTCToLocal(format: "HH:mm") + " " + order.updated_at.UTCToLocal(format: "dd/MM/yyyy")
        lblTitle.text = title
        
        if order.status == AppConfig.status.order.rejected() {
            vwTitle.backgroundColor = #colorLiteral(red: 1, green: 0.231372549, blue: 0.1882352941, alpha: 1)
        } else if order.status == AppConfig.status.order.progress() {
            vwTitle.backgroundColor = #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)
        } else if order.status == AppConfig.status.order.create_new() {
            vwTitle.backgroundColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        } else if order.status == AppConfig.status.order.finish() {
            vwTitle.backgroundColor = #colorLiteral(red: 0.05098039216, green: 0.6039215686, blue: 0.007843137255, alpha: 1)
        }
    }
    
    private func configView() {

        navigationController?.setNavigationBarHidden(true, animated: false)
        
        vwContain.layer.masksToBounds = true
        vwContain.layer.cornerRadius = 10
        
        lblTitle.adjustsFontSizeToFitWidth = true
       
        setEvent(button: btnClose)
    }
    
    func setEvent(button:UIButton) {
         button.addTarget(self, action: #selector(actionButton), for: .touchUpInside)
        button.layer.cornerRadius = 5
        button.setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for: UIControlState())
    }
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.alpha = 0
        
        inforController = OrderConfirmController(nibName: "OrderConfirmController", bundle: Bundle.main)
        
        addChildViewController(inforController)
        stackContainer.addArrangedSubview(inforController.view)
        inforController.onShouldClose = {[weak self] in
            guard let _self = self else {return}
            _self.actionButton(_self.btnClose)
        }
        
        inforController.onUpdateStateOrder = {[weak self] order in
            guard let _self = self else {return}
            _self.order = order
            _self.setupInformationOrder()
        }
        
        // Do any additional setup after loading the view.
        configView()
        setupInformationOrder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 0.2, animations: {
            self.view.alpha = 1
            self.view.transform = CGAffineTransform(scaleX: 1, y: 1)
        })
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if vwContain.frame.size.height > self.view.frame.size.height {
            centerConstraintVwContainer.priority = 1
            topConstraintVwContainer.priority = 250
        } else {
            topConstraintVwContainer.priority = 1
            centerConstraintVwContainer.priority = 250
        }
    }
    
    // MARK: - outlet
    @IBOutlet weak var vwContain: UIView!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var stackContainer: UIStackView!
    @IBOutlet weak var topConstraintVwContainer: NSLayoutConstraint!
    @IBOutlet weak var centerConstraintVwContainer: NSLayoutConstraint!
    @IBOutlet weak var vwTitle: UIView!
    
    // MARK: - properties
    var inforController:OrderConfirmController! {
        didSet {
            inforController.type = type == .view ? .view : .edit
            inforController.order = self.order
        }
    }
    var order:Order?
    var type:OrderDetailType = .view
    var startPoint:CGPoint = CGPoint.zero
    var isFirstLaunch:Bool = true
    
    // MARK: - closures
}
