//
//  Product.swift
//  SanTube
//
//  Created by Dai Pham on 1/5/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import Foundation

struct OrderItem {
    
    var id:String = ""
    var name:String = ""
    var description:String = ""
    var image:String = ""
    var shortDescription:String = ""
    var limitPerPerson:Int?
    var quantity:Int = 0
    var userId:String?
    var price:Float = 0
    var status:String = ""
}

extension OrderItem {
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
        
        if let data = dictionary["quantity"] as? String {
            self.quantity = Int(data)!
        } else if let data = dictionary["quantity"] as? Int {
            self.quantity = data
        }
        
        if let data = dictionary["limitPerPerson"] as? String {
            self.limitPerPerson = Int(data)!
        } else if let data = dictionary["limitPerPerson"] as? Int {
            self.limitPerPerson = data
        }
        
        if let data = dictionary["price"] as? String {
            self.price = Float(data)!
        } else if let data = dictionary["price"] as? Float {
            self.price = data
        }
        
        if let data = dictionary["status"] as? String {
            self.status = data
        } else if let data = dictionary["status"] as? Int {
            self.status = "\(data)"
        }
        
        if let data = dictionary["description"] as? String {
            self.description = data
        }
        
        if let data = dictionary["shortDescription"] as? String {
            self.shortDescription = data
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
    
    static func parse(from dictionary: JSON) -> Product{
        var stream = Product()
        stream.parse(from: dictionary)
        return stream
    }
}
