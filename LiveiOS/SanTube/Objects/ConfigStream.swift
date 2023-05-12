//
//  ConfigStream.swift
//  SanTube
//
//  Created by Dai Pham on 11/27/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import Foundation

class ConfigStream:NSObject {
    var ip: String = ""
    var port: String = ""
    var username: String = ""
    var password: String = ""
    
    static let current = ConfigStream()
    
    private override init() {
        super.init()
        if let current = ConfigManager.current() {
            self.parse(current.toDict)
        }
    }
}

extension ConfigStream {
     func parse(_ dictionary:JSON) {
        if let data = dictionary["ip"] as? String {
            self.ip = data
        }
        
        if let data = dictionary["port"] as? String {
            self.port = data
        }
        
        if let data = dictionary["username"] as? String {
            self.username = data
        }
        
        if let data = dictionary["password"] as? String {
            self.password = data
        }
    }
}
