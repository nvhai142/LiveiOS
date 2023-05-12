//
//  UserManager.swift
//  BUUP
//
//  Created by Dai Pham on 11/14/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import Foundation
import CoreData

class AccountManager: NSObject {
    static func currentUser() -> UserDO? {
        // Initialize Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "UserDO")
        
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let result = try CoreDataStack.sharedInstance.persistentContainer.viewContext.fetch(fetchRequest)
            var list:[UserDO] = []
            list = result.flatMap({$0 as? UserDO})
            if list.count > 0 {
                return list.first!
            } else {
                return nil
            }
            
        } catch {
            let fetchError = error as NSError
            print(fetchError)
            return nil
        }
    }
    
    static func save() {
        let context = CoreDataStack.sharedInstance.persistentContainer.viewContext
        do {
            try context.save()
        } catch {
            // TODO: handle the error
        }
    }
    
    static func reset(_ onComplete:(()->Void)) {
        let context = CoreDataStack.sharedInstance.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<UserDO>(entityName: "UserDO")
        fetchRequest.returnsObjectsAsFaults = false
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        
        do {
            try context.execute(deleteRequest)
            onComplete()
        } catch {
            onComplete()
            // TODO: handle the error
        }
    }
    
    static func saveUserWith(dictionary: JSON,_ context:NSManagedObjectContext,_ isGuest:Bool = false,_ onComplete:((Bool)->Void)){
        AccountManager.reset {
            if let user = NSEntityDescription.insertNewObject(forEntityName: "UserDO", into: context) as? UserDO {
                if let data = dictionary["id"] as? String {
                    user.id = data
                } else if let data = dictionary["id"] as? Int {
                    user.id = "\(data)"
                }
                
                if let data = dictionary["status"] as? String {
                    user.status = data
                } else if let data = dictionary["status"] as? Int64 {
                    user.status = "\(data)"
                }
                
                if let data = dictionary["email"] as? String {
                    user.email = data
                }
                
                if let data = dictionary["password"] as? String {
                    user.password = data
                }
                
                if let data = dictionary["name"] as? String {
                    user.name = data
                }
                
                if let data = dictionary["gender"] as? String {
                    user.gender = data
                }
				
				if let data = dictionary["language"] as? String {
					user.language = data
				}
                
                if let data = dictionary["dateOfBirth"] as? String {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    if let myDate = dateFormatter.date(from: data) {
                        user.dateOfBirth = myDate as NSDate
                    }
                }
                
                if let data = dictionary["website"] as? String {
                    user.website = data
                }
                
                if let data = dictionary["phone"] as? String {
                    user.phone = data
                }
                
                if let data = dictionary["avatar"] as? String {
                    user.avatar = data
                }
				
				if let data = dictionary["cover_image"] as? String {
					user.cover_image = data
				}
                
                if let data = dictionary["api_token"] as? String {
                    user.api_token = data
                }
                
                if let data = dictionary["createdDate"] as? String {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    if let myDate = dateFormatter.date(from: data) {
                        user.createdDate = myDate as NSDate
                    }
                }
                
                user.is_guest = isGuest
                
                AccountManager.save()
                onComplete(true)
            } else {
                onComplete(false)
            }
        }
    }
}
