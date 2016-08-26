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
    
    convenience init(pin: Pin, image: NSData? = UIImagePNGRepresentation(UIImage(named: "placeholder_2.png")!), date: NSDate? = NSDate.distantPast(), url: String, context: NSManagedObjectContext){
        
        if let ent = NSEntityDescription.entityForName("Photo",
                                                       inManagedObjectContext: context){
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.photoToPin = pin
            self.imageData = image
            self.date = date
            self.url = url
            self.local = false
            
        } else{
            fatalError("Unable to find Entity name!")
        }
        
    }

}
