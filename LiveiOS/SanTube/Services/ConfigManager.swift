//
//  ConfigManager.swift
//  BUUP
//
//  Created by Dai Pham on 11/14/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import Foundation
import CoreData

class ConfigManager: NSObject {
    
    static func current() -> ConfigDO? {
        // Initialize Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ConfigDO")
        
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let result = try CoreDataStack.sharedInstance.persistentContainer.viewContext.fetch(fetchRequest)
            var list:[ConfigDO] = []
            list = result.flatMap({$0 as? ConfigDO})
            if list.count > 0 {
                return list.last!
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
        let fetchRequest = NSFetchRequest<ConfigDO>(entityName: "ConfigDO")
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
    
    static func saveUserWith(dictionary: JSON,_ context:NSManagedObjectContext,_ onComplete:((Bool)->Void)? = nil){
        ConfigManager.reset {
            if let object = NSEntityDescription.insertNewObject(forEntityName: "ConfigDO", into: context) as? ConfigDO {
                
                if let data = dictionary["ip"] as? String {
                    object.ip = data
                }
                
                if let data = dictionary["port"] as? String {
                    object.port = data
                }
                
                if let data = dictionary["username"] as? String {
                    object.username = data
                }
                
                if let data = dictionary["password"] as? String {
                    object.password = data
                }
                
                ConfigManager.save()
                onComplete?(true)
            }
            onComplete?(false)
        }
    }
}
