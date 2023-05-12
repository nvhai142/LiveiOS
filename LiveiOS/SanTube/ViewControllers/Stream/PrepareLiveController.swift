//
//  PrepareLiveController.swift
//  SanTube
//
//  Created by Dai Pham on 11/17/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class PrepareLiveController: BaseController {

    // MARK: - properties
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let user = Account.current {
            if user.is_guest {
                let vc = AuthenticController(nibName: "AuthenticController", bundle: Bundle.main)
                let nv = UINavigationController(rootViewController: vc)
                self.tabBarController?.present(nv, animated: false)
                vc.onDissmiss = {[weak self] in
                    guard let tabbar = self?.tabBarController else {return}
                    tabbar.selectedIndex = 0
                }
            } else {
                let live = LiveStreamController(nibName: "LiveStreamController", bundle: Bundle.main)
                self.navigationController?.present(live, animated: false)
                live.onDissmissing = {[weak self] in
                    guard let tabbar = self?.tabBarController else {return}
                    tabbar.selectedIndex = 0
                }
            }
        }  else {
            let vc = AuthenticController(nibName: "AuthenticController", bundle: Bundle.main)
            let nv = UINavigationController(rootViewController: vc)
            AppConfig.navigation.changeRootControllerTo(viewcontroller: nv)
        }
    }
}
