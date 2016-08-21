//
//  TravelLocationsViewController.swift
//  Virtual Tourist
//
//  Created by Tim on 3/06/16.
//  Copyright © 2016 Tim. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsViewController : UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        mapView.delegate = self;
    }
    
    
    /**
     Event handler for long-press gestures on the map. Determines the geographic coordinate 
     for the point under the user's finger and creates a new pin
    */
    @IBAction func pressedOnMap(sender: UILongPressGestureRecognizer) {
        
        if (sender.state == UIGestureRecognizerState.Ended){
            let touchCoordinate = sender.locationInView(self.mapView);
            let mapCoordinate = mapView.convertPoint(touchCoordinate, toCoordinateFromView: self.mapView);
            addPinToMapAtCoordinate(coordinate: mapCoordinate);
            
        }
    }
    
    
    /**
     Adds a pin to the main map at a given geographic coordinate
     
     - Parameters:
        - coordinate: The geographic coordinate at which to drop a pin
     
     */
    func addPinToMapAtCoordinate(coordinate coord : CLLocationCoordinate2D){
        let pin = MKPointAnnotation();
        pin.coordinate = coord;
        mapView.addAnnotation(pin);
    }
    
    

}
