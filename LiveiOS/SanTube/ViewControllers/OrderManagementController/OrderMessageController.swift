//
//  OrderMessageController.swift
//  SanTube
//
//  Created by Dai Pham on 1/12/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class OrderMessageController: BaseController {

    // MARK: - event
    func touch(sender:UITapGestureRecognizer) {
        close()
    }
    
    // MARK: - private
    private func configView() {
        imvAlert.image = #imageLiteral(resourceName: "ic_check_128")
        
        vwContainer.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
        vwContainer.layer.shadowOffset = CGSize(width:0.5, height:4.0)
        vwContainer.layer.shadowOpacity = 0.5
        vwContainer.layer.shadowRadius = 5.0
        vwContainer.layer.cornerRadius = 5
        
        lblNote.textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        lblNote.font = UIFont.systemFont(ofSize: fontSize13)
    }
    
    private func removeAllTimers() {
        timerAutoClose?.invalidate()
        timerAutoClose = nil
    }
    
    private func close() {
        removeAllTimers()
        self.navigationController?.dismiss(animated: false, completion: nil)
    }
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()

        tapGestureView = UITapGestureRecognizer(target: self, action: #selector(touch))
        tapGestureContainer = UITapGestureRecognizer(target: self, action: #selector(touch))
        view.addGestureRecognizer(tapGestureView)
        vwContainer.addGestureRecognizer(tapGestureContainer)
        
        configView()
        
        if let mess = message {
            lblMessage.text = mess
        } else {
            lblMessage.text = ""
        }
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        var i = 4
        self.lblNote.text = "auto_close".localized().capitalizingFirstLetter() + " (\(i))"
        timerAutoClose = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {[weak self] timer in
            guard let _self = self else {return}
            i -= 1
            _self.lblNote.text = "auto_close".localized().capitalizingFirstLetter() + " (\(i))"
            if Date().timeIntervalSince(_self.dateOpenThis) > 3 {
                _self.close()
            }
        })
    }

    deinit {
        removeAllTimers()
        view.removeGestureRecognizer(tapGestureView)
        vwContainer.removeGestureRecognizer(tapGestureContainer)
    }
    
    // MARK: - properties
    var tapGestureContainer:UITapGestureRecognizer!
    var tapGestureView:UITapGestureRecognizer!
    var message:String?
    var timerAutoClose:Timer?
    var dateOpenThis:Date = Date()
    
    // MARK: - outlet
    @IBOutlet weak var vwContainer: UIView!
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var imvAlert: UIImageViewRound!
    @IBOutlet weak var lblNote: UILabel!
    
}
