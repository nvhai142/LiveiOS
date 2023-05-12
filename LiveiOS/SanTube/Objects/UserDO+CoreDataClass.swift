//
//  UserDO+CoreDataClass.swift
//  BUUP
//
//  Created by Dai Pham on 11/14/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//
//

import Foundation
import CoreData

@objc(UserDO)
public class UserDO: NSManagedObject {

    var toDictionary:JSON {
        var date_of_birth = ""
        if let created = dateOfBirth as Date?{
            date_of_birth = created.toString(dateFormat: "yyyy-MM-dd HH:mm:ss")
        }
        
        var created_date = ""
        if let created = createdDate as Date?{
            created_date = created.toString(dateFormat: "yyyy-MM-dd HH:mm:ss")
        }
        
        return [
            "id": id ?? "",
            "name": name ?? "",
            "website": website ?? "",
            "status": status ?? "0",
            "avatar": avatar ?? "",
			"cover_image": cover_image ?? "",
            "email": email ?? "",
            "password": password ?? "",
            "language": language ?? "",
            "gender": gender ?? "",
			"phone": phone ?? "",
            "api_token": api_token ?? "",
            "dateOfBirth": date_of_birth,
            "createdDate": created_date,
            "is_guest": is_guest
        ]
    }
}
