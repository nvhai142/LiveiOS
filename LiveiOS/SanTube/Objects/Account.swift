//
//  Users.swift
//  BUUP
//
//  Created by Dai Pham on 11/13/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import Foundation

struct Account {
    var id: String = ""
    var first_name:String = ""
    var last_name:String = ""
    var link:String = ""
    var gender:String = "female"
    var locale:String = ""
    var avatar:String?
    var api_token:String = ""
    var name:String = ""
    var isGuest:Bool = false
    
    static var current:User? {
        if let user = AccountManager.currentUser() {
            return User.parse(from: user.toDictionary)
        }
        return nil
    }
}
