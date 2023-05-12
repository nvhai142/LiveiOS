//
//  BaseApplyController.swift
//  SanTube
//
//  Created by Dai Pham on 12/19/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class BaseApplyQuickVideoController: BaseController {

    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let tabbarVC = self.tabBarController as? BaseTabbarController else { return }
        tabbarVC.delegate = self
        tabbarVC.registerControllerPresent = self.navigationController
    }
    
    // MARK: - override
    func configQuickView() {
        guard let tabbarVC = self.tabBarController as? BaseTabbarController else { return }
        tabbarVC.configQuickView()
    }
    
    func prepareToOpenStream() {
        guard let tabbarVC = self.tabBarController as? BaseTabbarController else { return }
        tabbarVC.prepareToOpenStream()
    }
    
    func closeQuickView() {
        guard let tabbarVC = self.tabBarController as? BaseTabbarController else { return }
        tabbarVC.closeQuickView()
    }
    
    func minimizeQuickView() {
        guard let tabbarVC = self.tabBarController as? BaseTabbarController else { return }
        tabbarVC.minimizeQuickView()
    }
    
    func fullScreenView() {
        guard let tabbarVC = self.tabBarController as? BaseTabbarController else { return }
        tabbarVC.fullScreenView()
    }
}

// MARK: - tabbar delegate // turn off quick view when change tabbar
extension BaseApplyQuickVideoController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let view = viewController as? UINavigationController {
            if let vc = view.viewControllers.first {
                if !vc.isKind(of: FeaturedController.self) {
                    guard let window = viewController.tabBarController?.view.window else { return true}
                    let quickViewController = window.quickViewcontroller()
                    quickViewController.releaseQuickview()
                }
            }
        }
        return true
    }
}
