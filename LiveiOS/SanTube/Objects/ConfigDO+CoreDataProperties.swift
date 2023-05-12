//
//  ConfigDO+CoreDataProperties.swift
//  BUUP
//
//  Created by Dai Pham on 11/14/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//
//

import Foundation
import CoreData


extension ConfigDO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ConfigDO> {
        return NSFetchRequest<ConfigDO>(entityName: "ConfigDO")
    }

    @NSManaged public var ip: String?
    @NSManaged public var port: String?
    @NSManaged public var username: String?
    @NSManaged public var password: String?

}
