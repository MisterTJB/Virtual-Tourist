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

class PhotoAlbumViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var latitude: CLLocationDegrees?
    var longitude: CLLocationDegrees?
    
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
        let photoFetchRequest = NSFetchRequest(entityName: "Photo")
        
        
        let sortDescriptor = NSSortDescriptor(key: "identifier", ascending: true)
        photoFetchRequest.sortDescriptors = [sortDescriptor]
        
        // Only fetch Photos having this Pin as its parent
        let format = "photoToPin.latitude BETWEEN {\(self.latitude! - 0.0001), \(self.latitude! + 0.0001)} AND photoToPin.longitude BETWEEN {\(self.longitude! - 0.0001), \(self.longitude! + 0.0001)} "
        photoFetchRequest.predicate = NSPredicate(format: format)
        
        // Initialize Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: photoFetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    lazy var pin: Pin = {
        // Initialize Fetch Request
        let pinFetchRequest = NSFetchRequest(entityName: "Pin")
        
        // Only fetch Pins associated with the coordinate that this PhotoAlbumViewController is 
        
        let format = "latitude BETWEEN {\(self.latitude! - 0.0001), \(self.latitude! + 0.0001)} AND longitude BETWEEN {\(self.longitude! - 0.0001), \(self.longitude! + 0.0001)} "
        pinFetchRequest.predicate = NSPredicate(format: format)
        
        // Initialize Fetched Results Controller
        var result: AnyObject?
        do{
            try result = self.sharedContext.executeFetchRequest(pinFetchRequest)[0]
        } catch {
            print ("Could not execute fetch request for Pin")
        }
        return result as! Pin
        
    }()
    
    override func viewDidLoad() {
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        print ("Loaded photo album with latitude \(latitude), longitude \(longitude)")
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
        }
        
//        if let results = fetchedResultsController.fetchedObjects {
//            if results.count == 0 {
//                FlickrDownloadManager.downloadImagesForCoordinate(CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)) { imageData, error in
//                    print ("Download images completed – trying to create Photos")
//                    if let image = imageData {
//                        Photo(pin: self.pin, image: image, context: self.sharedContext)
//                        print("Created Photo object")
//                    } else {
//                        print("There was an error")
//                    }
//                }
//
//            }
//        }
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
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let width = collectionView.frame.width / 3.5
        return CGSize(width: width, height: width)
    }
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print ("Trying to delete Photo with index \(indexPath.item)")
        if let photoToDelete = fetchedResultsController.fetchedObjects?[indexPath.item] as? Photo {
            sharedContext.deleteObject(photoToDelete)
            print ("Deleted photo at index \(indexPath.item)")
        }
        
        
    }
    
    
    
}