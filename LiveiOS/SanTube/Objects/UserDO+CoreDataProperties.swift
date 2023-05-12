//
//  UserDO+CoreDataProperties.swift
//  SanTube
//
//  Created by Dai Pham on 3/5/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//
//

import Foundation
import CoreData


extension UserDO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserDO> {
        return NSFetchRequest<UserDO>(entityName: "UserDO")
    }

    @NSManaged public var api_token: String?
    @NSManaged public var avatar: String?
    @NSManaged public var cover_image: String?
    @NSManaged public var createdDate: NSDate?
    @NSManaged public var dateOfBirth: NSDate?
    @NSManaged public var email: String?
    @NSManaged public var gender: String?
    @NSManaged public var id: String?
    @NSManaged public var language: String?
    @NSManaged public var locale: String?
    @NSManaged public var name: String?
    @NSManaged public var password: String?
    @NSManaged public var phone: String?
    @NSManaged public var status: String?
    @NSManaged public var website: String?
    @NSManaged public var is_guest: Bool

}
