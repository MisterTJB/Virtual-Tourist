//
//  Pin+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Tim on 4/06/16.
//  Copyright © 2016 Tim. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Pin {

    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var pinToPhotos: NSSet?

}
