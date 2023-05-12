//
//  AppConfig.swift
//  BUUP
//
//  Created by Dai Pham on 11/7/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import Foundation
import Localize_Swift
import FacebookLogin
import FBSDKLoginKit

class AppConfig: NSObject {
    
    // MARK: - Feature
    class func isUnlockQuickLogin() -> Bool {
        if let plistPath = Bundle.main.path(forResource: "NewFeature", ofType: "plist") {
            if let dict = NSDictionary.init(contentsOfFile: plistPath) {
                if let bool = dict.value(forKey: "QuickLogin") as? Bool {
                    return bool
                }
            }
        }
        
        return false
    }
    
    // MARK: - Show Case
    class showCase: AppConfig {
        static func isShowTutorial(with key:String) -> Bool {
            if let remember =  UserDefaults.standard.value(forKey: key) as? Bool {
                return remember
            }
            return false
        }
        
        static func setFinishShowcase(key:String) {
            if key.characters.count == 0 {return}
            UserDefaults.standard.setValue(true, forKey: key)
        }
        
        static func resetTutorial() {
            for key in LIST_SCENES {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
    
    // MARK: - language
    class cached: AppConfig {
        static var getCacheCategories: [JSON]? {
            if(UserDefaults.standard.data(forKey: "AppConfig:Cached:Categories") != nil) {
                if let listT = NSKeyedUnarchiver.unarchiveObject(with:UserDefaults.standard.value(forKey: "AppConfig:Cached:Categories") as! Data) as? [JSON] {
                    return listT
                }
                
            }
            return []
        }
        
        static func setCacheCategories(data:[JSON]) {
            UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject:data), forKey: "AppConfig:Cached:Categories")
            UserDefaults.standard.synchronize()
        }
    }
    
    // MARK: - language
    class language: AppConfig {
        static var getCurrentLanguage: String {
            if(UserDefaults.standard.string(forKey: "AppConfig:Language") != nil) {
                return UserDefaults.standard.string(forKey: "AppConfig:Language")!
            } else {
                return "en"
            }
        }
        
        static func setLanguage(language:String) {
            let availableLanguages = Localize.availableLanguages()
            if(!availableLanguages.contains(language)) {
                return;
            }
            let currentLanguage = AppConfig.language.getCurrentLanguage
            if(currentLanguage != language) {
                Localize.setCurrentLanguage(language)
                UserDefaults.standard.set(language, forKey: "AppConfig:Language")
                
            }
        }
    }
    
    // MARK: - navigation
    class navigation: AppConfig {
        static func logOut() {
            let loginManage = LoginManager()
            loginManage.logOut()
            FBSDKAccessToken.setCurrent(nil)
            UserDefaults.standard.set(false, forKey: "APP::HadShowelcome")
            AccountManager.reset {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "App::UserLogoutSuccess"), object: nil, userInfo: ["action":"logout"])
                }
            }
        }
        
        static func gotoHomeAfterSigninSuccess() {
            
            let vc = BaseTabbarController()
            let sb = UIStoryboard(name: "Main", bundle: Bundle.main)
            let uinaviVC1 = UINavigationController.init(rootViewController: HomeController(nibName: "HomeController", bundle: Bundle.main))
            let uinaviVC2 = UINavigationController.init(rootViewController: PrepareLiveController())
            let uinaviVC3 = UINavigationController.init(rootViewController: PrepareProfileController())
            let uinaviVC4 = UINavigationController.init(rootViewController: sb.instantiateViewController(withIdentifier: "followerManager"))
            let uinaviVC5 = UINavigationController.init(rootViewController: sb.instantiateViewController(withIdentifier: "orderHistory"))
            
            vc.setViewControllers([uinaviVC1,uinaviVC4,uinaviVC2,uinaviVC5,uinaviVC3], animated: true)
            
            let itemHome = UITabBarItem(title: nil, image: UIImage(named: "ic_home_96")?.tint(with: UIColor(hex:"0x5b5b5b")).withRenderingMode(.alwaysOriginal), selectedImage: UIImage(named: "ic_home_96")?.tint(with: UIColor(hex:"0xFCCE2F")).withRenderingMode(.alwaysOriginal))
            uinaviVC1.tabBarItem  = itemHome

            let itemLiveStream = UITabBarItem(title: nil, image: UIImage(named: "ic_live_128")?.tint(with: UIColor(hex:"0xff0000")).withRenderingMode(.alwaysOriginal), selectedImage: UIImage(named: "ic_live_128")?.tint(with: UIColor(hex:"0xFCCE2F")).withRenderingMode(.alwaysOriginal))
            uinaviVC2.tabBarItem  = itemLiveStream

            let itemGroup = UITabBarItem(title: nil, image: UIImage(named: "ic_profile")?.tint(with: UIColor(hex:"0x5b5b5b")).withRenderingMode(.alwaysOriginal), selectedImage: UIImage(named: "ic_profile")?.tint(with: UIColor(hex:"0xFCCE2F")).withRenderingMode(.alwaysOriginal))
            uinaviVC3.tabBarItem  = itemGroup

            let itemCalendar = UITabBarItem(title: nil, image: UIImage(named: "icon_subscribe")?.tint(with: UIColor(hex:"0x5b5b5b")).withRenderingMode(.alwaysOriginal), selectedImage: UIImage(named: "icon_subscribe")?.tint(with: UIColor(hex:"0xFCCE2F")).withRenderingMode(.alwaysOriginal))
            uinaviVC4.tabBarItem  = itemCalendar

            let itemCommu = UITabBarItem(title: nil, image: UIImage(named: "ic_bt_cart_96")?.tint(with: UIColor(hex:"0x5b5b5b")).withRenderingMode(.alwaysOriginal), selectedImage:UIImage(named: "ic_bt_cart_96")?.tint(with: UIColor(hex:"0xFCCE2F")).withRenderingMode(.alwaysOriginal))
            uinaviVC5.tabBarItem  = itemCommu

            if #available(iOS 11.0, *) {
                if UI_USER_INTERFACE_IDIOM() != .pad {
                    uinaviVC1.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
                    uinaviVC2.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
                    uinaviVC3.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
                    uinaviVC4.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
                    uinaviVC5.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
                }
            } else {
                uinaviVC1.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
                uinaviVC2.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
                uinaviVC3.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
                uinaviVC4.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
                uinaviVC5.tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
            }

            uinaviVC1.tabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.clear], for: UIControlState())
            uinaviVC2.tabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.clear], for: UIControlState())
            uinaviVC3.tabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.clear], for: UIControlState())
            uinaviVC4.tabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.clear], for: UIControlState())
            uinaviVC5.tabBarItem.setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.clear], for: UIControlState())
            
            AppConfig.navigation.changeRootControllerTo(viewcontroller: vc,animated: false)
        }
        
        static func ifNotHaveMarkFaviousCategories() {
            
            let navigation = AppConfig.navigation.self
            
            guard let user = Account.current else {
                AppConfig.navigation.logOut()
                return
            }

            Server.shared.getCategories(!user.is_guest ? user.id : nil, loadCache: false) { result in
                switch result {
                case .success(let list):
                    AppConfig.cached.setCacheCategories(data: list)
                    let listCategories = list.flatMap{Category.parse(from: $0)}.filter{!$0.name.contains("Others")}
                    let countFavious = listCategories.filter{$0.isMarked == true}
                    
                    if countFavious.count < 3 && !user.is_guest{
                        let vc = WelcomeController(nibName: "WelcomeController", bundle: Bundle.main)
                        navigation.changeRootControllerTo(viewcontroller: vc,animated: true)
                    } else {
                        navigation.gotoHomeAfterSigninSuccess()
                    }
                case .failure(let msg):
                    print(msg as Any)
                    navigation.gotoHomeAfterSigninSuccess()
                }
                
            }
        }
        
        static func changeRootControllerTo(viewcontroller:UIViewController, animated:Bool? = false,_ complete:((Bool)->Void)? = nil) {
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            
            var duration:Double  = 0
            if let animate = animated {
                if animate {duration = 0.3}
            }
            
            if let window = appdelegate.window {
                if let tb = UIApplication.shared.keyWindow?.rootViewController as? BaseTabbarController {
                    tb.viewControllers = nil
                }
                UIView.transition(with: window, duration: duration, options: .transitionCrossDissolve, animations: {
                    window.rootViewController?.view.removeFromSuperview()
                    window.rootViewController = nil
                    window.rootViewController = viewcontroller
                    window.makeKeyAndVisible()
                    appdelegate.window = window
                }, completion:complete)
            }
        }
        
        static func changeController(to:UIViewController, on:UITabBarController, index:Int) {
            if let listNaviControllers = on.viewControllers {
                if let navi = listNaviControllers[index] as? UINavigationController {
                    navi.setViewControllers([to], animated: false)
                }
            }
        }
    }
    
    // MARK: - Project Status
    class status: AppConfig {
        
        static func getValue(key:String,_ keyStore:String)->String? {
            if(UserDefaults.standard.data(forKey: keyStore) != nil) {
                if let data = NSKeyedUnarchiver.unarchiveObject(with:UserDefaults.standard.value(forKey: keyStore) as! Data) as? JSON {
                    return data[key] as? String
                }
            }
            return nil
        }
        
        class stream: status {
            static func save(data:JSON) {
                UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject:data), forKey: "AppConfig:Stream:Status")
                UserDefaults.standard.synchronize()
            }
            
            static func stop()->String {return getValue(key: SS_STOP,"AppConfig:Stream:Status") ?? "unknown"}
            static func start()->String {return getValue(key: SS_START,"AppConfig:Stream:Status") ?? "unknown"}
            static func streaming()->String {return getValue(key: SS_STREAMING,"AppConfig:Stream:Status") ?? "unknown"}
            static func failure()->String {return getValue(key: SS_FAIL,"AppConfig:Stream:Status") ?? "unknown"}
        }
       
        class order: status {
            static func save(data:JSON) {
                UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject:data), forKey: "AppConfig:Order:Status")
                UserDefaults.standard.synchronize()
            }
            
            static func create_new()->String {return getValue(key: SO_NEW,"AppConfig:Order:Status") ?? "unknown"}
            static func progress()->String {return getValue(key: SO_PROGRESS,"AppConfig:Order:Status") ?? "unknown"}
            static func rejected()->String {return getValue(key: SO_REJECT,"AppConfig:Order:Status") ?? "unknown"}
            static func finish()->String {return getValue(key: SO_FINISH,"AppConfig:Order:Status") ?? "unknown"}
            static func delete()->String {return getValue(key: SO_DELETE,"AppConfig:Order:Status") ?? "unknown"}
        }
        
        class user: status {
            static func save(data:JSON) {
                UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject:data), forKey: "AppConfig:User:Status")
                UserDefaults.standard.synchronize()
            }
            
            static func active()->String {return getValue(key: SU_ACTIVE,"AppConfig:User:Status") ?? "unknown"}
            static func inactive()->String {return getValue(key: SU_INACTIVE,"AppConfig:User:Status") ?? "unknown"}
            static func banned()->String {return getValue(key: SU_BANNED,"AppConfig:User:Status") ?? "unknown"}
        }
        
        class product: status {
            static func save(data:JSON) {
                UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject:data), forKey: "AppConfig:Product:Status")
                UserDefaults.standard.synchronize()
            }
            
            static func create_new()->String {return getValue(key: SP_NEW,"AppConfig:Product:Status") ?? "unknown"}
            static func delete()->String {return getValue(key: SP_DELETE,"AppConfig:Product:Status") ?? "unknown"}
        }
    }
}
