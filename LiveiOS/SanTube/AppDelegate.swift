//
//  AppDelegate.swift
//  BUUP
//
//  Created by Hai NguyenV on 10/30/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FacebookLogin

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // reset show case
//        AppConfig.showCase.resetTutorial()
        
        // config navigation bar
        UINavigationBar.appearance().isTranslucent = false        
        UINavigationBar.appearance().barTintColor = UIColor(hex:"0xFCCE2F")
        UINavigationBar.appearance().tintColor = UIColor(hex:"0x6599FF")
        
        // config tabbar
        UITabBar.appearance().isTranslucent = false
//        UITabBar.appearance().tintColor = UIColor(hex:"0xff0000")
//        UITabBar.appearance().barTintColor = UIColor(hex:"0xededed")
        
        // set directory for coredata
        CoreDataStack.sharedInstance.applicationDocumentsDirectory()
        
        // set root controller
        window = UIWindow.init(frame: UIScreen.main.bounds)
        let vc = LaunchController(nibName: "LaunchController", bundle: Bundle.main)
        if let ww = window {
            ww.rootViewController = vc
            ww.makeKeyAndVisible()
        }
        
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        FBSDKAppEvents.activateApp()
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        if url.host == nil
        {
            return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation);
        }
        
        
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

