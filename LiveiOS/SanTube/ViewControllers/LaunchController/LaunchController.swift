//
//  LaunchController.swift
//  SanTube
//
//  Created by Dai Pham on 11/20/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FacebookLogin

class LaunchController: UIViewController {

    // MARK: - outlet
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        indicator.startAnimating()
        nextStep()
    }
    
    // MARK: - private
    func nextStep() {
        // check if user not login yet
        if let acc = Account.current {
            if acc.id.characters.count == 0 || acc.api_token.characters.count == 0 {
                /* apply quick login */
                let vc = AuthenticController(nibName: "AuthenticController", bundle: Bundle.main)
                AppConfig.navigation.changeRootControllerTo(viewcontroller: vc)
 /*
                Server.shared.loginGuest { [weak self] err in
                    guard let _self = self else {return}
                    if let err = err {
                        var msg = ""
                        switch err {
                        case .unkownData:
                            msg = "user_not_exist".localized().capitalizingFirstLetter()
                        case .invalidService:
                            msg = "service_unavailable".localized()
                        default:
                            msg = "Unkown error!"
                        }
                        Support.notice(title:"notice".localized().capitalizingFirstLetter(),message: msg,vc: _self, ["ok".localized().uppercased()], nil)
                    } else {
                        DispatchQueue.main.async {
                            let vc = HomeController(nibName: "HomeController", bundle: Bundle.main)
                            AppConfig.navigation.changeRootControllerTo(viewcontroller: vc)
                        }
                    }
 
                }
 */
            } else {
                
                // remove order mark deleted
                if let order = Support.orderDeleted.getOrderDeleted() {
                    Server.shared.changeStatusOrder(orderIds: [order.id],
                                                    status: AppConfig.status.order.delete()) {(order, err) in
                    }
                }
                
                // get config
                Server.shared.getConfig {[weak self] _ in
                    guard let _self = self else {return}
                    Server.shared.getConfigStatus({ (json, err) in
                        guard let json = json else {
                            _self.showError()
                            return
                        }
                        if err == nil {
                            if let orders = json["orders"] as? JSON {
                                AppConfig.status.order.save(data: orders)
                            }
                            
                            if let stream = json["streams"] as? JSON {
                                AppConfig.status.stream.save(data: stream)
                            }
                            
                            if let stream = json["products"] as? JSON {
                                AppConfig.status.product.save(data: stream)
                            }
                            
                            if let stream = json["users"] as? JSON {
                                AppConfig.status.user.save(data: stream)
                            }
                            
                            // get categories
                            _self.indicator.stopAnimating()
                            AppConfig.navigation.ifNotHaveMarkFaviousCategories()
                        } else {
                            _self.showError()
                        }
                    })
                }
                
            }
        } else {
            // change to quick login
            
            let vc = AuthenticController(nibName: "AuthenticController", bundle: Bundle.main)
            let nv = UINavigationController(rootViewController: vc)
            AppConfig.navigation.changeRootControllerTo(viewcontroller: nv)
            
            
            /*
            Server.shared.loginGuest { [weak self] err in
                guard let _self = self else {return}
                
                if let err = err {
                    var msg = ""
                    switch err {
                    case .unkownData:
                        msg = "user_not_exist".localized().capitalizingFirstLetter()
                    case .invalidService:
                        msg = "service_unavailable".localized()
                    default:
                        msg = "Unkown error!"
                    }
                    Support.notice(title:"notice".localized().capitalizingFirstLetter(),message: msg,vc: _self, ["ok".localized().uppercased()], nil)
                } else {
                    DispatchQueue.main.async {
                        let vc = HomeController(nibName: "HomeController", bundle: Bundle.main)
                        AppConfig.navigation.changeRootControllerTo(viewcontroller: vc)
                    }
                }
            }
*/
        }
    }
    
    private func showError() {
        let actionSheetController: UIAlertController = UIAlertController(title: "error".localized().capitalized, message: "service_unavailable".localized() + ": api::allstatus", preferredStyle: .alert)
        let cancelAction: UIAlertAction = UIAlertAction(title: "OK", style: .cancel) { action -> Void in
            //Just dismiss the action sheet
        }
        actionSheetController.addAction(cancelAction)
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    deinit {
        print("LauchController deinit")
    }
}
