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

class PhotoAlbumViewController : UIViewController, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet var feedbackLabel: UILabel!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var newCollectionButton: UIBarButtonItem!
    
    var latitude: CLLocationDegrees?
    var longitude: CLLocationDegrees?
    
    lazy var sharedContext: NSManagedObjectContext = {
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
        
        // Find the Pin associated with this coordinate
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
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        setMapRegion()
        addPinToMapForAlbumCoordinates()
        preparePhotoObjects()
    }
    
    /**
     Determine whether an Pin has already had Photos associated with it. If not, Photo 
     objects are created and associated with the Pin.
     */
    func preparePhotoObjects(){
        
        // Retrieve relevant images from CoreData
        do {
            try fetchedResultsController.performFetch()
            print ("Loaded photo album with latitude \(latitude!), longitude \(longitude!)")
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
        }
        
        // If no Photo objects are associated with this Pin, query Flickr for relevant images
        if (fetchedResultsController.fetchedObjects?.count == 0){
            downloadImagesFromFlickr()
        }
    }
    
    /**
     Downloads image URLs from Flickr and -- for each URL -- creates Photo objects with a placeholder 
     image
     */
    func downloadImagesFromFlickr(){
        newCollectionButton.enabled = false
        feedbackLabel.text = "Searching Flickr..."
        feedbackLabel.hidden = false
        FlickrDownloadManager.downloadImagesForPinAndSaveInContext(pin, context: self.sharedContext){ error in
            
            if let error = error {
                self.feedbackLabel.text = "Network Error"
                self.feedbackLabel.hidden = false
                print (error)
            } else {
                self.feedbackLabel.hidden = true
                FlickrDownloadManager.downloadImagesForPhotos(self.fetchedResultsController.fetchedObjects as! [Photo])
            }
            
            // If there are no photos associated with this location, show the noImagesLabel
            if self.fetchedResultsController.fetchedObjects?.count == 0 {
                self.feedbackLabel.text = "No Images"
                self.feedbackLabel.hidden = false
            }
        }
    }
    
    @IBAction func newCollection(sender: UIBarButtonItem) {
        for photo in fetchedResultsController.fetchedObjects! {
            sharedContext.deleteObject(photo as! Photo)
        }
        stack.save()
        
        feedbackLabel.hidden = true
        downloadImagesFromFlickr()
    }
    
    
    
    /**
     Determine if the photos for this photo album is in a downloading state
     
     - Returns: true if all of the Photos have been downloaded; false otherwise
     */
    func finishedDownloading() -> Bool {
        let photos = fetchedResultsController.fetchedObjects as! [Photo]
        var retVal = true
        for photo in photos{
            retVal = retVal && photo.local
        }
        return retVal
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

extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let width = (collectionView.frame.width - 20) / 3
        return CGSize(width: width, height: width)
    }

}

extension PhotoAlbumViewController: UICollectionViewDataSource {
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print("Called controllerDidChangeContent")
        collectionView.reloadData()
        if finishedDownloading() {
            self.newCollectionButton.enabled = true
        }
    }

}

// MARK: Manage the display of images in the UICollectionView

extension PhotoAlbumViewController: UICollectionViewDelegate {

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let photoToDelete = fetchedResultsController.fetchedObjects?[indexPath.item] as? Photo {
            sharedContext.deleteObject(photoToDelete)
            stack.save()
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects!.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath)
        
        if let photo = fetchedResultsController.fetchedObjects?[indexPath.item] as? Photo {
            
            // Add the Photo's image data to the cell
            if let image = UIImage(data: photo.imageData!) {
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: cell.bounds.width, height: cell.bounds.height))
                imageView.image = image
                imageView.contentMode = .ScaleAspectFill
                cell.addSubview(imageView)
            }
            
        }
        return cell
    }

}