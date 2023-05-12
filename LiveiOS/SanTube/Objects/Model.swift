//
//  Model.swift
//  Live
//
//  Created by leo on 16/7/13.
//  Copyright © 2016年 io.ltebean. All rights reserved.
//

import Foundation

struct Room {
    
    var stream_id: String
    var user_id: String
    var api_token: String
    
    init(dict: [String: AnyObject]) {
        user_id = dict["user_id"] as! String
        stream_id = dict["stream_id"] as! String
        api_token = dict["api_token"] as! String
    }
    
    func toDict() -> [String: AnyObject] {
        return [
            "user_id": user_id as AnyObject,
            "stream_id": stream_id as AnyObject,
            "api_token": api_token as AnyObject
        ]
    }
    func toDictCreate()-> [String: AnyObject] {
        return [
            "stream_id": stream_id as AnyObject
        ]
    }
}


struct Comment {
    
    var text: String
    
    init(dict: [String: AnyObject]) {
        text = dict["text"] as! String
    }
}



