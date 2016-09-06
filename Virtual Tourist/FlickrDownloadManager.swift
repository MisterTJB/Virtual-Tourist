//
//  FlickrDownloadManager.swift
//  Virtual Tourist
//
//  Created by Tim on 21/08/16.
//  Copyright © 2016 Tim. All rights reserved.
//

import Foundation
import Alamofire
import MapKit



class FlickrDownloadManager {
    
    
    /**
     Download images from Flickr containing data about images in the region of a given coordinate
     
     - Parameters:
        - coordinate: The coordinate about which to search for images
        - completion: The completion handler to call, returning an image (represented as NSData) or 
     an error to the caller
     
     */
    static func downloadImagesForCoordinate(coordinate : CLLocationCoordinate2D, completion: ([[String:AnyObject]]?, NSError?) -> Void){
        
        getNumPagesForCoordinate(coordinate){ pages, error in
            
            print("Got number of pages")
            
            guard let pages = pages else {
                completion(nil, error)
                return
            }
            
            print ("Choosing random page")
            // Restrict upper bound to 100 to prevent Flickr bug
            let pagesUpperBound = min(pages, 100)
            let randomPage = arc4random_uniform(UInt32(pagesUpperBound)) + 1
            print ("Random page is \(randomPage)")
            
        
            Alamofire.request(
                .GET,
                "https://api.flickr.com/services/rest/",
                parameters: ["method": "flickr.photos.search",
                "api_key": "a4ebce9cbae74391014b23471293fb42",
                "lat": coordinate.latitude,
                "lon": coordinate.longitude,
                "per_page": "21",
                "page": Int(randomPage),
                "format": "json",
                "nojsoncallback": "1",
                "extras": "url_m,date_taken"],
                encoding: .URL)
                .validate()
                .responseJSON { (response) -> Void in
                    print (response.request?.URLString)
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
                    
                    print ("Search results returned, about to pass back URL")
                    print ("URL: \(photo[0]["url_m"]!)")
                    completion(photo, nil)
                }
            
                
        }
    
    }
    
    /**
     Determine how many pages of results a Flickr search will return
     
     - Parameters:
     - coordinate: The coordinate about which to search for images
     - completion: The completion handler to call, returning an image (represented as NSData) or
     an error to the caller
     
     */
    private static func getNumPagesForCoordinate(coordinate : CLLocationCoordinate2D, completion: (Int?, NSError?) -> Void){
        
        Alamofire.request(
            .GET,
            "https://api.flickr.com/services/rest/",
            parameters: ["method": "flickr.photos.search",
                "api_key": "a4ebce9cbae74391014b23471293fb42",
                "lat": coordinate.latitude,
                "lon": coordinate.longitude,
                "per_page": "21",
                "format": "json",
                "nojsoncallback": "1",
                "extras": "url_m,date_taken"],
            encoding: .URL)
            .validate()
            .responseJSON { (response) -> Void in
                guard response.result.isSuccess else {
                    print("Error while fetching photos: \(response.result.error)")
                    completion(nil, NSError(domain: "Initial Flickr request was unsuccessful", code: 0, userInfo: nil))
                    return
                }
                
                guard let result = response.result.value as? [String: AnyObject],
                    let photos = result["photos"] as? [String: AnyObject] else {
                        completion(nil, NSError(domain: "Initial Flickr request response was malformed", code: 0, userInfo: nil))
                        return
                }
                
                print ("Search result will return \(photos["pages"]) results")
                completion(photos["pages"] as! Int, nil)
        }
    
    }
    
    /**
     Download an image from Flickr
     
     - Parameters:
        - parameters: A dictionary containing, at least, key-value pairs for farm, server, id, 
     and secret
        - completion: The completion handler to call after an image has been downloaded
     */
     static func downloadImageWithUrl(url: String, completion: (NSData?, NSError?) -> Void){
//        let farm = parameters["farm"]
//        let server = parameters["server"]
//        let id = parameters["id"]
//        let secret = parameters["secret"]
//        let url = "https://farm\(farm!).staticflickr.com/\(server!)/\(id!)_\(secret!)_m.jpg"
        
        
        print ("URL: \(url)")
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