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
        restoreMapRegion();
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
        print ("Dropped pin at \(coord)")
        
    }
    
    /**
     Create a new Pin managed object and save it in CoreData
     
     - Parameters:
        - coordinate: The geographic coordinate for the new Pin
     */
    func persistNewPinAtCoordinate(coordinate coord: CLLocationCoordinate2D){
        Pin(coordinate: coord, context: sharedContext)
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
        
        if let coordinate = view.annotation?.coordinate {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let photoAlbumViewController = storyboard.instantiateViewControllerWithIdentifier("PhotoAlbumView") as! PhotoAlbumViewController
            photoAlbumViewController.longitude = coordinate.longitude
            photoAlbumViewController.latitude = coordinate.latitude
            navigationController?.pushViewController(photoAlbumViewController, animated: true)
        
        }
        
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let latitude = mapView.region.center.latitude
        let longitude = mapView.region.center.longitude
        let latitudeDelta = mapView.region.span.latitudeDelta
        let longitudeDelta = mapView.region.span.longitudeDelta
        
        NSUserDefaults.standardUserDefaults().setDouble(latitude, forKey: "userLatitude")
        NSUserDefaults.standardUserDefaults().setDouble(longitude, forKey: "userLongitude")
        NSUserDefaults.standardUserDefaults().setDouble(latitudeDelta, forKey: "userLatitudeDelta")
        NSUserDefaults.standardUserDefaults().setDouble(longitudeDelta, forKey: "userLongitudeDelta")
    }
    
    func restoreMapRegion(){
        let latitude = NSUserDefaults.standardUserDefaults().doubleForKey("userLatitude")
        let longitude = NSUserDefaults.standardUserDefaults().doubleForKey("userLongitude")
        let latitudeDelta = NSUserDefaults.standardUserDefaults().doubleForKey("userLatitudeDelta")
        let longitudeDelta = NSUserDefaults.standardUserDefaults().doubleForKey("userLongitudeDelta")
        
        if (latitude != 0 && longitude != 0 && latitudeDelta != 0 && longitudeDelta != 0){
        
            let coordinateToRestore = CLLocationCoordinate2DMake(latitude, longitude)
            let spanToRestore = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        
            let region = MKCoordinateRegion(center: coordinateToRestore, span: spanToRestore)
            mapView.setRegion(region, animated: true)
        }
        
    }

}
