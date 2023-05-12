//
//  BaseController.swift
//  BUUP
//
//  Created by Dai Pham on 11/15/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

import CoreData
import Localize_Swift

class BaseController: UIViewController {

    // MARK: - closures
    var onDissmiss:(()->Void)?
    
    // MARK: - properties
    var btnProfile:UIButton!
    var btnNotification:UIButton!
    var btnSearch:UIButton!
    var btnBack:UIButton!
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // so update prrofile avatar user always
        if let user = Account.current, let tb = tabBarController, let vc = tb.viewControllers?.last {
            if let url = URL(string: user.avatar) {
                URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                    if let data = data {
                        if let downloadedImage = UIImage(data: data) {
                            DispatchQueue.main.async {
                                vc.tabBarItem = UITabBarItem(title: "test", image: downloadedImage.resizeImageWith(newSize: CGSize(width: 30, height: 30)).maskRoundedImage(radius: 15).withRenderingMode(.alwaysOriginal), selectedImage:nil)
                                
                                if #available(iOS 11.0, *) {
                                    if UI_USER_INTERFACE_IDIOM() != .pad {
                                        vc.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
                                    }
                                } else {
                                    vc.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
                                }
                                
                                vc.tabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.clear], for: UIControlState())
                            }
                        }
                    }
                }).resume()
            }
        }
        
        if let items = tabBarController?.tabBar.items {
            for item in items {
                item.title = ""
            }
        }
    }
    
    deinit {
       
        #if DEBUG
            print("\(self.description) dealloc")
        #endif
		
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UpdateButtonProfile"), object: nil)
    }

    
    // MARK: - interface
    func addDefaultMenu () {
        
        let widthAvatar = CGFloat(40)
        // add right menu
        // profile
        btnProfile = UIButton(type: .custom)
        btnProfile.frame = CGRect(x: 0, y: 0, width: widthAvatar, height: widthAvatar)
        
        let imageView:UIImageView = UIImageView(image: UIImage(named: "ic_profile"))
        imageView.tag = 1111
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = widthAvatar / 2
        if let user = Account.current {
            btnProfile.imageView!.layer.cornerRadius = widthAvatar / 2
            imageView.loadImageUsingCacheWithURLString(user.avatar,size:nil, placeHolder: nil)
			NotificationCenter.default.addObserver(self, selector: #selector(self.updateBtnProfile), name: NSNotification.Name(rawValue: "UpdateButtonProfile"), object: nil)
        }
        btnProfile.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: widthAvatar).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: widthAvatar).isActive = true
        imageView.centerXAnchor.constraint(equalTo: btnProfile.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: btnProfile.centerYAnchor).isActive = true
        imageView.layer.borderColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor
        imageView.layer.borderWidth = 1
        
        btnProfile.addTarget(self, action: #selector(self.menuPress(sender:)), for: .touchUpInside)
        let itemProfile = UIBarButtonItem(customView: btnProfile)
        
        // back
        btnBack = UIButton(type: .custom)
        btnBack.frame = CGRect(x: 0, y: 0, width: widthAvatar*70/100, height: widthAvatar)
        btnBack.contentMode = .scaleAspectFill
        btnBack.clipsToBounds = true
        btnBack.semanticContentAttribute = .forceLeftToRight
        btnBack.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
        btnBack.setImage(UIImage(named:"arrow_left_white_48")?.tint(with: UIColor.white), for: UIControlState())
        btnBack.addTarget(self, action: #selector(self.menuPress(sender:)), for: .touchUpInside)
        let itemBack = UIBarButtonItem(customView: btnBack)
        self.navigationItem.leftBarButtonItems = [itemProfile]
        if let vc = self.navigationController {
            if vc.viewControllers.count > 1 {
                self.navigationItem.leftBarButtonItems = [itemBack/*,itemProfile*/]
            }
        }
        
            
        // notification
        btnNotification = UIButton(type: .custom)
        btnNotification.frame = CGRect(x: 0, y: 0, width: widthAvatar, height: widthAvatar)
        btnNotification.contentMode = .right
        btnNotification.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -10)
        btnNotification.clipsToBounds = true
        btnNotification.setImage(UIImage(named:"ic_bell_blue_76")?.tint(with: UIColor.white), for: UIControlState())
        btnNotification.addTarget(self, action: #selector(self.menuPress(sender:)), for: .touchUpInside)
        let itemNotification = UIBarButtonItem(customView: btnNotification)
        
        // search
        btnSearch = UIButton(type: .custom)
        btnSearch.frame = CGRect(x: 0, y: 0, width: widthAvatar, height: widthAvatar)
        btnSearch.contentMode = .right
        btnSearch.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -10)
        btnSearch.clipsToBounds = true
        btnSearch.setImage(UIImage(named:"ic_search")?.tint(with: UIColor.white), for: UIControlState())
        btnSearch.addTarget(self, action: #selector(self.menuPress(sender:)), for: .touchUpInside)
        let itemSearch = UIBarButtonItem(customView: btnSearch)
        
        self.navigationItem.rightBarButtonItems  = [itemNotification,itemSearch]
    }
    
    // MARK: - private
    @objc func menuPress(sender:UIButton) {
        
        if sender.isEqual(btnProfile) {
            let storyBoard = UIStoryboard.init(name: "Main", bundle: Bundle.main)
            let nv = UINavigationController(rootViewController: storyBoard.instantiateViewController(withIdentifier: "ProfileController"))
            Support.topVC!.present(nv, animated: true, completion: nil)
        } else if sender.isEqual(btnBack) {
            if let vc = self.navigationController {
                if vc.viewControllers.count > 1 {
                    self.navigationController?.popViewController(animated: true)
                } else {
                    self.navigationController?.dismiss(animated: true, completion: nil)
                }
            }
        } else if sender.isEqual(btnSearch) {
            return
            let vc = QRScanController(nibName: "QRScanController", bundle: Bundle.main)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
	@objc func updateBtnProfile() {
		guard let imageView = btnProfile.viewWithTag(1111) as? UIImageView,
			let acc = Account.current else {
				
			return
		}
		
		imageView.loadImageUsingCacheWithURLString(acc.avatar, size: nil, placeHolder: nil, false)
	}
}
