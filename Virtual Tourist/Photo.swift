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
    
    convenience init(pin : Pin, context : NSManagedObjectContext){
        
        if let ent = NSEntityDescription.entityForName("Photo",
                                                       inManagedObjectContext: context){
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.photoToPin = pin
            self.identifier = "JUNK"
            if let img = UIImage(named: "TEST_IMG.jpg") {
                self.imageData = UIImageJPEGRepresentation(img, 1.0)
            }
            
            
        } else{
            fatalError("Unable to find Entity name!")
        }
        
    }

}
