//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Tim on 4/06/16.
//  Copyright © 2016 Tim. All rights reserved.
//

import Foundation
import CoreData
import MapKit


class Pin: NSManagedObject {

    convenience init(coordinate coord : CLLocationCoordinate2D,  context : NSManagedObjectContext){
        
        if let ent = NSEntityDescription.entityForName("Pin",
                                                       inManagedObjectContext: context){
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.latitude = coord.latitude
            self.longitude = coord.longitude
        } else{
            fatalError("Unable to find Entity name!")
        }
        
    }
}
