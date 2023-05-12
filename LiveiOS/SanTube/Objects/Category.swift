//
//  Categories.swift
//  BUUP
//
//  Created by Dai Pham on 11/13/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import Foundation

struct Category {
    var id:String = ""
    var name:String = ""
    var img:String = ""
    var iconUrl:String = ""
    var order:Int = 0
    var isMarked:Bool = false
    var isAll:Bool = false
    
    static func parse(from dictionary: JSON) -> Category{
        var cate = Category()
        cate.parse(from: dictionary)
        return cate
    }
    
    static func categoryAll()->Category {
        var cate = Category()
        cate.id = "0"
        cate.isAll = true
        cate.isMarked = true
        cate.iconUrl = "ic_all_categories"
        cate.name = "all_categories".localized()
        return cate
    }
}

extension Category {
    mutating func parse(from dictionary: JSON) {
        if let data = dictionary["id"] as? String {
            self.id = data
        } else if let data = dictionary["id"] as? Int {
            self.id = "\(data)"
        }
        
        if let data = dictionary["order"] as? String {
            self.order = Int(data)!
        } else if let data = dictionary["order"] as? Int {
            self.order = data
        }
        
        if let data = dictionary["name"] as? String {
            self.name = data
        }
        
        if let data = dictionary["img"] as? String {
            self.img = data
        }
        
        if let data = dictionary["iconUrl"] as? String {
            self.iconUrl = data
        }
        
        if let data = dictionary["isMarked"] as? Bool {
            self.isMarked = data
        }
    }
}
