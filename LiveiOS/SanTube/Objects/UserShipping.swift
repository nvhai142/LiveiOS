//
//  Product.swift
//  SanTube
//
//  Created by Dai Pham on 1/5/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import Foundation

struct UserShipping {
    
    var id:String = ""
    var name:String = ""
    var shippingName:String = ""
    var shippingAddress:String = ""
    var shippingPhone:String = ""
    var userId:String?
    
    func isValid()->Bool {
        return  shippingName.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).characters.count > 0 &&
                shippingPhone.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).characters.count > 0 &&
                shippingAddress.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).characters.count > 0 &&
                userId != nil
    }
    
    func toDict() -> JSON{
        return ["id":id,
                "userId":userId ?? "",
                "shippingName":shippingName,
                "shippingAddress":shippingAddress,
                "shippingPhone":shippingPhone]
    }
}

extension UserShipping {
    mutating func parse(from dictionary: JSON) {
        if let data = dictionary["id"] as? String {
            self.id = data
        } else if let data = dictionary["id"] as? Int {
            self.id = "\(data)"
        }
        
        if let data = dictionary["userId"] as? String {
            self.userId = data
        } else if let data = dictionary["userId"] as? Int {
            self.userId = "\(data)"
        }
        
        if let data = dictionary["shippingName"] as? String {
            self.shippingName = data
        }
        
        if let data = dictionary["shippingAddress"] as? String {
            self.shippingAddress = data
        }
        
        if let data = dictionary["shippingPhone"] as? String {
            self.shippingPhone = data
        }
        
        if let data = dictionary["name"] as? String {
            var mix = data
            
//            if mix.contains("\\") {
//                mix = String(data: mix.data(using: String.Encoding.utf8)!, encoding: String.Encoding.nonLossyASCII)!
//            } else {
//                mix = String(data: mix.data(using: String.Encoding.utf8)!, encoding: String.Encoding.utf8)!
//            }
            
            if mix.characters.count == 0 {
                mix = data
            }
            self.name = mix
        }
        
       
    }
    
    static func parse(from dictionary: JSON) -> UserShipping{
        var stream = UserShipping()
        stream.parse(from: dictionary)
        return stream
    }
}
