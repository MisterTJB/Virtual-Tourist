//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Tim on 4/06/16.
//  Copyright © 2016 Tim. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Photo: NSManagedObject {
    
    convenience init(pin : Pin, imageData: NSData, context : NSManagedObjectContext){
        
        if let ent = NSEntityDescription.entityForName("Photo",
                                                       inManagedObjectContext: context){
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.photoToPin = pin
            self.imageData = imageData
            self.identifier = "JUNK"
            
        } else{
            fatalError("Unable to find Entity name!")
        }
        
    }

}
