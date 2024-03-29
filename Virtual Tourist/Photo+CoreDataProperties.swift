//
//  Photo+CoreDataProperties.swift
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

extension Photo {

    @NSManaged var imageData: NSData?
    @NSManaged var photoToPin: NSManagedObject?
    @NSManaged var date: NSDate?
    @NSManaged var url: String?
    @NSManaged var local: Bool

}
