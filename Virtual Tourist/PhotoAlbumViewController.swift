//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Tim on 3/06/16.
//  Copyright © 2016 Tim. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotoAlbumViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    lazy var sharedContext: NSManagedObjectContext = {
        // Get the stack
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let stack = delegate.stack
        return stack.context
    }()
    
    lazy var stack: CoreDataStack = {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return delegate.stack
    }()
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        // Initialize Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        // TODO Add NSPredicate to get THIS Pin's photos
        let sortDescriptor = NSSortDescriptor(key: "identifier", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Initialize Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
        }
        

    }
    
    @IBAction func newCollection(sender: UIBarButtonItem) {
        // TODO The Photo Album view has a button that initiates the download 
        // of a new album, replacing theimages in the photo album with a new 
        // set from Flickr.
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Called numberOfItemsInSection")
        return fetchedResultsController.fetchedObjects!.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        print("Called cellForItemAtIndexPath")
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath)
        guard let photo = fetchedResultsController.fetchedObjects?[indexPath.item] as? Photo,
            image = UIImage(data: photo.imageData!) else {
                print("Could not load stored image")
                return cell
        }
        let imageView = UIImageView(frame:CGRectMake(   0,
            0,
            (collectionView.collectionViewLayout
                .collectionViewContentSize().width / 2)
                - (0.5),
            (collectionView.collectionViewLayout
                .collectionViewContentSize().width / 2)
                - (0.5)))
        imageView.contentMode = .ScaleAspectFill
        imageView.image = image
        cell.addSubview(imageView)
        return cell
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print("Called controllerDidChangeContent")
        collectionView.reloadData()
    }
    
    
    
    
}