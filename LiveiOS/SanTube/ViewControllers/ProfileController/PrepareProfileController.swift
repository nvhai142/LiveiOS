//
//  PrepareProfileController.swift
//  SanTube
//
//  Created by Dai Pham on 3/2/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class PrepareProfileController: BaseController {

    // MARK: - properties
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let appConfig = AppConfig.self
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
                let storyBoard = UIStoryboard.init(name: "Main", bundle: Bundle.main)
                let vc = storyBoard.instantiateViewController(withIdentifier: "ProfileController") as! ProfileController
                let nv = UINavigationController(rootViewController: vc)
                self.tabBarController?.present(nv, animated: false)
                vc.onDissmiss = {[weak self] in
                    guard let tabbar = self?.tabBarController else {return}
                    tabbar.selectedIndex = 0
                }
                
                vc.onSignOut = {[weak self] in
                    guard let _ = self else {return}
                    appConfig.navigation.logOut()
                }
            }
        } else {
            let vc = AuthenticController(nibName: "AuthenticController", bundle: Bundle.main)
            let nv = UINavigationController(rootViewController: vc)
            AppConfig.navigation.changeRootControllerTo(viewcontroller: nv)
        }
    }

    deinit {
        
        print("PrepareProfileController dealloc")
    }
}
