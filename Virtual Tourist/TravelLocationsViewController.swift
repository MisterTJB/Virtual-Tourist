//
//  TravelLocationsViewController.swift
//  Virtual Tourist
//
//  Created by Tim on 3/06/16.
//  Copyright © 2016 Tim. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsViewController : UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
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
    
    override func viewDidLoad() {
        mapView.delegate = self
        loadPersistedPins()
    }
    
    
    /**
     Event handler for long-press gestures on the map. Determines the geographic coordinate 
     for the point under the user's finger and creates a new pin
    */
    @IBAction func pressedOnMap(sender: UILongPressGestureRecognizer) {
        
        if (sender.state == UIGestureRecognizerState.Ended){
            let touchCoordinate = sender.locationInView(self.mapView)
            let mapCoordinate = mapView.convertPoint(touchCoordinate, toCoordinateFromView: self.mapView)
            persistNewPinAtCoordinate(coordinate: mapCoordinate);
            addPinToMapAtCoordinate(coordinate: mapCoordinate)
            
        }
    }
    
    
    /**
     Adds a pin to the main map at a given geographic coordinate
     
     - Parameters:
        - coordinate: The geographic coordinate at which to drop a pin
     
     */
    func addPinToMapAtCoordinate(coordinate coord : CLLocationCoordinate2D){
        let pin = MKPointAnnotation()
        pin.coordinate = coord
        mapView.addAnnotation(pin)
        
    }
    
    /**
     Create a new Pin managed object and save it in CoreData
     
     - Parameters:
        - coordinate: The geographic coordinate for the new Pin
     */
    func persistNewPinAtCoordinate(coordinate coord: CLLocationCoordinate2D){
        let pin = Pin(coordinate: coord, context: sharedContext)
        
        FlickrDownloadManager.downloadImagesForCoordinate(coord) { imageData, error in
            print ("Download images completed – trying to create Photos")
            if let image = imageData {
                Photo(pin: pin, imageData: image, context: self.sharedContext)
                print("Created Photo object")
            } else {
                print("There was an error")
            }
        }
        stack.save()
        print ("Saved pin with coordinate \(coord)")
    }
    
    
    /**
     Load any persisted pins from CoreData and display them on the map
     */
    func loadPersistedPins(){
        print("Loading persisted pins")
        let fetch = NSFetchRequest(entityName: "Pin")
        
        do {
            let pins = try sharedContext.executeFetchRequest(fetch) as! [Pin]
            for pin in pins {
                let coordinate = CLLocationCoordinate2D(latitude: Double(pin.latitude!), longitude: Double(pin.longitude!))
                addPinToMapAtCoordinate(coordinate: coordinate)
            }
        } catch {
            print ("Couldn't load Pins from sharedContext")
        }
    }
    
    
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let photoAlbumViewController = storyboard.instantiateViewControllerWithIdentifier("PhotoAlbumView") as! PhotoAlbumViewController
        navigationController?.pushViewController(photoAlbumViewController, animated: true)
    }
    
    

}
