//
//  Users.swift
//  BUUP
//
//  Created by Dai Pham on 11/13/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import Foundation

struct User {
    var id: String = ""
    var email:String = ""
    var password:String = ""
    var name:String = ""
    var gender:String = ""
    var dateOfBirth:Date?
    var language:String = ""
    var website:String = ""
    var phone:String = ""
	var cover_image:String = ""
    var avatar:String = ""
    var createdDate:Date?
    var status:String = ""
    var api_token:String = ""
    var address:String = ""
    var is_guest:Bool = false
    
    static func parse(from dictionary: JSON) -> User{
        var user = User()
        user.parse(from: dictionary)
        return user
    }
}
extension User {
    
    mutating func parse(from dictionary: JSON) {
        
        if let data = dictionary["id"] as? String {
            self.id = data
        } else if let data = dictionary["id"] as? Int {
            self.id = "\(data)"
        }
        
        if let data = dictionary["status"] as? String {
            self.status = data
        } else if let data = dictionary["status"] as? Int {
            self.status = "\(data)"
        }
        
        if let data = dictionary["email"] as? String {
            self.email = data
        }
        
        if let data = dictionary["password"] as? String {
            self.password = data
        }
        
        if let data = dictionary["name"] as? String {
            self.name = data
        }
        
        if let data = dictionary["gender"] as? String {
            self.gender = data
        }
		
		if let data = dictionary["language"] as? String {
			self.language = data
		}
        
        if let data = dictionary["dateOfBirth"] as? String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            if let myDate = dateFormatter.date(from: data) {
                self.dateOfBirth = myDate
            }
        }
        
        if let data = dictionary["website"] as? String {
            self.website = data
        }
        
        if let data = dictionary["phone"] as? String {
            self.phone = data
        }
        
        if let data = dictionary["avatar"] as? String {
            self.avatar = data
        }
		
		if let data = dictionary["cover_image"] as? String {
			self.cover_image = data
		}
        
        if let data = dictionary["address"] as? String {
            self.address = data
        }
        
        if let data = dictionary["gender"] as? String {
            self.gender = data
        }
        
        if let data = dictionary["api_token"] as? String {
            self.api_token = data
        }
        
        if let data = dictionary["is_guest"] as? Bool {
            self.is_guest = data
        }
        
        if let data = dictionary["createdDate"] as? String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            if let myDate = dateFormatter.date(from: data) {
                self.createdDate = myDate
            }
        }
    }
}
