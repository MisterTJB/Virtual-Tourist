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
    @IBOutlet var noImagesLabel: UILabel!
    @IBOutlet var mapView: MKMapView!
    
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
        
        
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
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
        setMapRegion()
        addPinToMapForAlbumCoordinates()
        
        // TODO LoadImagesForPin() // If Pin has no photos, download; else Load
        
        
        
        do {
            try fetchedResultsController.performFetch()
            print ("Loaded photo album with latitude \(latitude!), longitude \(longitude!)")
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
        }
        
        if (fetchedResultsController.fetchedObjects?.count == 0){
            FlickrDownloadManager.downloadImagesForCoordinate(CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)){ photoData, error in
                
                if let photoData = photoData {
                    for photo in photoData {
                        if let url = photo["url_m"] as? String {
                            Photo(pin: self.pin, url: url, context: self.sharedContext)
                        }
                    }
                    self.stack.save()
                    
                }
                if photoData?.count == 0 {
                    self.noImagesLabel.hidden = false
                }
                
            }
        
        }
    }
    
    @IBAction func newCollection(sender: UIBarButtonItem) {
        // TODO The Photo Album view has a button that initiates the download 
        // of a new album, replacing theimages in the photo album with a new 
        // set from Flickr.
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return fetchedResultsController.fetchedObjects!.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath)
        
        if let photo = fetchedResultsController.fetchedObjects?[indexPath.item] as? Photo {
            
            if photo.local == false {
                
                FlickrDownloadManager.downloadImageWithUrl(photo.url!) { data, error in
                    
                    if let data = data {
                        photo.imageData = data
                        photo.local = true
                        self.stack.save()
                    }
                    
                }
                
            }
            
            if let image = UIImage(data: photo.imageData!) {
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: cell.bounds.width, height: cell.bounds.height))
                imageView.image = image
                imageView.contentMode = .ScaleAspectFill
                cell.addSubview(imageView)
            }
            
        }
        return cell
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print("Called controllerDidChangeContent")
        collectionView.reloadData()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let width = (collectionView.frame.width - 20) / 3
        return CGSize(width: width, height: width)
    }
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print ("Trying to delete Photo with index \(indexPath.item)")
        if let photoToDelete = fetchedResultsController.fetchedObjects?[indexPath.item] as? Photo {
            sharedContext.deleteObject(photoToDelete)
            stack.save()
            print ("Deleted photo at index \(indexPath.item)")
        }
        
        
    }
    
    /**
     Sets the displayed region for the map view, such that the region is centered 
     on the coordinates for this album
     
     - Parameters:
        - latitudeDelta (optional): The latitude span for the region
        - longitudeDelta (optional): The longitude span for the region
     */
    func setMapRegion(latitudeDelta: Double = 1, longitudeDelta: Double = 1){
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!), span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta))
            mapView.setRegion(region, animated: true)
        
    }
    
    /**
     Adds a pin to the map view to indicate the approximate location for the 
     photos in the album
     */
    func addPinToMapForAlbumCoordinates() {
        let pin = MKPointAnnotation()
        pin.coordinate = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
        mapView.addAnnotation(pin)
        
    }

}