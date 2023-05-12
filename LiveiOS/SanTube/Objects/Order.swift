//
//  Product.swift
//  SanTube
//
//  Created by Dai Pham on 1/5/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import Foundation

struct Order {
    
    var id:String = ""
    var buyerId:String = ""
    var sellerId:String = ""
    var shippingId:String = ""
    var streamId:String = ""
    var created_at:String = ""
    var updated_at:String = ""
    var seller:User?
    var buyer:User?
    var totalPrice:Float = 0
    var status:String = AppConfig.status.order.create_new()
    var products:[Product] = []
    var userShipping:UserShipping?
    
    func toJSON() ->JSON {
        return ["id":id]
    }
}

extension Order {
    mutating func parse(from dictionary: JSON) {
        if let data = dictionary["id"] as? String {
            self.id = data
        } else if let data = dictionary["id"] as? Int {
            self.id = "\(data)"
        }
        
        if let data = dictionary["buyerId"] as? String {
            self.buyerId = data
        } else if let data = dictionary["buyerId"] as? Int {
            self.buyerId = "\(data)"
        }
        
        if let data = dictionary["sellerId"] as? String {
            self.sellerId = data
        } else if let data = dictionary["sellerId"] as? Int {
            self.sellerId = "\(data)"
        }
        
        if let data = dictionary["shippingId"] as? String {
            self.shippingId = data
        } else if let data = dictionary["shippingId"] as? Int {
            self.shippingId = "\(data)"
        }
        
        if let data = dictionary["streamId"] as? String {
            self.streamId = data
        } else if let data = dictionary["streamId"] as? Int {
            self.streamId = "\(data)"
        }
        
        if let data = dictionary["status"] as? String {
            self.status = data
        } else if let data = dictionary["status"] as? Int {
            self.status = "\(data)"
        }
        
        if let data = dictionary["totalPrice"] as? Float {
            self.totalPrice = data
        } else if let data = dictionary["totalPrice"] as? String {
            self.totalPrice = Float(data)!
        }
        
        if let data = dictionary["created_at"] as? String {
            self.created_at = data
        }
        
        if let data = dictionary["updated_at"] as? String {
            self.updated_at = data
        }
        
        if let data = dictionary["products"] as? [JSON] {
            self.products = data.flatMap{OrderItem.parse(from: $0)}
        }
        
        if let data = dictionary["shipping"] as? JSON {
            self.userShipping = UserShipping.parse(from: data)
        }
        
        if let data = dictionary["seller"] as? JSON {
            self.seller = User.parse(from: data)
        }
        
        if let data = dictionary["buyer"] as? JSON {
            self.buyer = User.parse(from: data)
        }
    }
    
    static func parse(from dictionary: JSON) -> Order{
        var stream = Order()
        stream.parse(from: dictionary)
        return stream
    }
}
