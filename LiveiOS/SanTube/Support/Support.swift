//
//  Support.swift
//  SanTube
//
//  Created by Dai Pham on 11/16/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

class Support: NSObject {
    
    // MARK: - Top Controller
    static var topVC:UIViewController? {
        var topVC = UIApplication.shared.keyWindow?.rootViewController
        while((topVC!.presentedViewController) != nil){
            topVC = topVC!.presentedViewController
        }
        return topVC
    }
    
    // MARK: - check internet connection
    class connectivity {
        class func isConnectedToInternet() ->Bool {
            return NetworkReachabilityManager()!.isReachable
        }
    }
    
    // MARK: - validate
    class validate: Support {
        
        static func isValidEmailAddress(emailAddressString: String) -> Bool {
            var returnValue = true
            let emailRegEx = "[A-Z0-9a-z.-_]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,3}"
            
            do {
                let regex = try NSRegularExpression(pattern: emailRegEx)
                let nsString = emailAddressString as NSString
                let results = regex.matches(in: emailAddressString, range: NSRange(location: 0, length: nsString.length))
                
                if results.count == 0
                {
                    returnValue = false
                }
                
            } catch let error as NSError {
                print("invalid regex: \(error.localizedDescription)")
                returnValue = false
            }
            
            return  returnValue
        }
        
        static func isValidPassword(password: String) -> Bool {
            var returnValue = true
            if(password.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).characters.count < 6) {
                returnValue = false
            }
            
            return  returnValue
        }
        
    }
    
    // MARK: - Alert
    class func notice(title:String, message:String,vc:UIViewController,_ buttons:[String] = ["ok".localized().uppercased()],_ action:((UIAlertAction)->Void)?) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        
        for (i,btnTitle) in buttons.enumerated() {
            if i > 2 {break}
            var type:UIAlertActionStyle = .cancel
            if i == 1 {
                type = .default
            } else if i == 2 {
                type = .destructive
            }
            ac.addAction(UIAlertAction(title: btnTitle, style: type, handler: action))
        }
        vc.present(ac, animated: true)
    }
    
    // MARK: - save order deleted
    class orderDeleted: Support {
        static func getOrderDeleted() -> Order? {
            if(UserDefaults.standard.data(forKey: "App:OrderDeleted") != nil) {
                if let data = NSKeyedUnarchiver.unarchiveObject(with:UserDefaults.standard.value(forKey: "App:OrderDeleted") as! Data) as? JSON {
                    return Order.parse(from: data)
                }
            }
            return nil
        }
        
        static func saveOrderDeleted(order:Order? = nil) {
            guard let order = order else {
                UserDefaults.standard.set(nil, forKey: "App:OrderDeleted")
                UserDefaults.standard.synchronize()
                return
            }
            UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject:order.toJSON()), forKey: "App:OrderDeleted")
            UserDefaults.standard.synchronize()
        }
    }
}
