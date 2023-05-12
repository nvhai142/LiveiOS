//
//  ConfigDO+CoreDataClass.swift
//  BUUP
//
//  Created by Dai Pham on 11/14/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//
//

import Foundation
import CoreData

@objc(ConfigDO)
public class ConfigDO: NSManagedObject {

    var toDict:JSON {
        return["ip":ip ?? "",
        "port":port ?? "",
        "username": username ?? "",
        "password": password ?? ""]
    }
}
