//
//  FlickrDownloadManager.swift
//  Virtual Tourist
//
//  Created by Tim on 21/08/16.
//  Copyright © 2016 Tim. All rights reserved.
//

import Foundation
import Alamofire
import UIKit
import MapKit



class FlickrDownloadManager {
    
    
    /**
     Download images from Flickr containing data about images in the region of a given coordinate
     
     - Parameters:
        - coordinate: The coordinate about which to search for images
        - completion: The completion handler to call, returning an image (represented as NSData) or 
     an error to the caller
     
     */
    static func downloadImagesForCoordinate(coordinate : CLLocationCoordinate2D, completion: (NSData?, NSError?) -> Void){
        
        Alamofire.request(
            .GET,
            "https://api.flickr.com/services/rest/",
            parameters: ["method": "flickr.photos.search",
            "api_key": "a4ebce9cbae74391014b23471293fb42",
            "lat": coordinate.latitude,
            "lon": coordinate.longitude,
            "format": "json",
            "nojsoncallback": "1",
            "extras": "url_m"],
            encoding: .URL)
            .validate()
            .responseJSON { (response) -> Void in
                guard response.result.isSuccess else {
                    print("Error while fetching photos: \(response.result.error)")
                    completion(nil, NSError(domain: "Initial Flickr request was unsuccessful", code: 0, userInfo: nil))
                    return
                }
                
                guard let result = response.result.value as? [String: AnyObject],
                    photos = result["photos"] as? [String: AnyObject],
                    photo = photos["photo"] as? [[String: AnyObject]] else {
                        completion(nil, NSError(domain: "Initial Flickr request response was malformed", code: 0, userInfo: nil))
                        return
                }
                
                print ("Search results returned, about to download images")
                for photoData in photo {
                
                    downloadImageWithFlickrParameters(photoData){ imageData, error in
                        
                        guard let data = imageData else {
                            completion(nil, error)
                            return
                        }
                        completion(data, nil)
                    
                    }
                }
                
                
        }
    
    }
    
    /**
     Download an image from Flickr
     
     - Parameters:
        - parameters: A dictionary containing, at least, key-value pairs for farm, server, id, 
     and secret
        - completion: The completion handler to call after an image has been downloaded
     */
    private static func downloadImageWithFlickrParameters(parameters: [String: AnyObject], completion: (NSData?, NSError?) -> Void){
        let farm = parameters["farm"]
        let server = parameters["server"]
        let id = parameters["id"]
        let secret = parameters["secret"]
        let url = "https://farm\(farm!).staticflickr.com/\(server!)/\(id!)_\(secret!)_m.jpg"
        
        
        print ("Trying to download from the test URL")
        request(.GET,url).response(){ _, _, data, error in
            if let error = error {
                print("Error downloading image")
                completion(nil, error)
            } else {
                print("Downloaded an image!")
                completion(data, nil)
            }
            
        }
    }



}