//
//  Stream.swift
//  BUUP
//
//  Created by Dai Pham on 11/13/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import Foundation

struct Stream {
    var id:String = ""
    var name:String = ""
    var description:String = ""
    var thumbnailUrl:String = ""
    var isFeatured:Bool = false
    var isLiked:Bool = false
    var noOfViews:Int64 = 0
    var noOfLikes:Int64 = 0
    var duration:Int = 0
    var offlineURL:String = ""
    var status:String = AppConfig.status.stream.stop()
    var startTime:String = ""
    var endTime:String = ""
    var santubeCode:String = ""
    var password:String = ""
    var user:User = User()
    var categories:[Category] = []
    var products:[Product] = []
}

extension Stream {
    mutating func parse(from dictionary: JSON) {
        if let data = dictionary["id"] as? String {
            self.id = data
        } else if let data = dictionary["id"] as? Int {
            self.id = "\(data)"
        }
        
        if let data = dictionary["status"] as? String {
            self.status = data
        }
        
        if let data = dictionary["noOfViews"] as? String {
            self.noOfViews = Int64(data)!
        } else if let data = dictionary["noOfViews"] as? Int64 {
            self.noOfViews = data
        }
        
        if let data = dictionary["noOfLikes"] as? String {
            self.noOfLikes = Int64(data)!
        } else if let data = dictionary["noOfLikes"] as? Int64 {
            self.noOfLikes = data
        }
        
        if let data = dictionary["duration"] as? String {
            self.duration = Int(data)!
        } else if let data = dictionary["duration"] as? Int {
            self.duration = data
        }
        
        if let data = dictionary["name"] as? String {
            var mix = data
            if mix.contains("\\") {
                mix = String(data: mix.data(using: String.Encoding.utf8)!, encoding: String.Encoding.nonLossyASCII)!
            } else {
                mix = String(data: mix.data(using: String.Encoding.utf8)!, encoding: String.Encoding.utf8)!
            }
            if mix.characters.count == 0 {
                mix = data
            }
            self.name = mix
        }
        
        if let data = dictionary["offlineUrl"] as? String {
            self.offlineURL = data
        }
        
        if let data = dictionary["santubeCode"] as? String {
            self.santubeCode = data
        }
        
        if let data = dictionary["password"] as? String {
            self.password = data
        }
        
        if let data = dictionary["thumbnailUrl"] as? String {
            self.thumbnailUrl = data
        }
        
        if let data = dictionary["description"] as? String {
            self.description = data
        }
        
        if let data = dictionary["startTime"] as? String {
            self.startTime = data
        }
        
        if let data = dictionary["endTime"] as? String {
            self.endTime = data
        }
        
        if let data = dictionary["isFeatured"] as? Bool {
            self.isFeatured = data
        }
        
        if let data = dictionary["isLiked"] as? Bool {
            self.isLiked = data
        }
        
        if let data = dictionary["user"] as? JSON {
            self.user = User.parse(from: data)
        }
        
        if let data = dictionary["categories"] as? [JSON] {
            if data.count > 0 {self.categories.removeAll()}
            for item in data {
                self.categories.append(Category.parse(from:item))
            }
        }
        if let data = dictionary["products"] as? [JSON] {
            if data.count > 0 {self.products.removeAll()}
            for item in data {
                self.products.append(Product.parse(from:item))
            }
        }
    }
    
    static func parse(from dictionary: JSON) -> Stream{
        var stream = Stream()
        stream.parse(from: dictionary)
        return stream
    }
    
    func timeStart() -> String {
        if self.startTime.characters.count > 0 {
            let time = Date().timeIntervalSince((self.startTime).toDate2())
            if time <= 60 {
                return "1 minute ago"
            } else if time >= 60 && time < 60*60 {
                let temp = round(time/(60))
                if temp > 1 {
                    return "\(Int(temp)) minutes ago"
                } else {
                    return "\(Int(temp)) minute ago"
                }
            } else if time >= 60*60 && time < 60*60*24 {
                let temp = round(time/(60*60))
                if temp > 1 {
                    return "\(Int(temp)) hours ago"
                } else {
                    return "\(Int(temp)) hour ago"
                }
            } else if time >= 60*60*24 && time < 60*60*24*7 {
                let temp = round(time/(60*60*24))
                if temp > 1 {
                    return "\(Int(temp)) days ago"
                } else {
                    return "\(Int(temp)) day ago"
                }
            } else if time >= 60*60*24*7 && time < 60*60*24*30 {
                let temp = round(time/(60*60*24*7))
                if temp > 1 {
                    return "\(Int(temp)) weeks ago"
                } else {
                    return "\(Int(temp)) week ago"
                }
            } else {
                let temp = round(time/(60*60*24*30))
                if temp > 1 {
                    return "\(Int(temp)) months ago"
                } else {
                    return "\(Int(temp)) month ago"
                }
            }
        }
        return ""
    }
}
