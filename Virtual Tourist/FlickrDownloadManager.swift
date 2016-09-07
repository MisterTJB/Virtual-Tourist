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
import CoreData



class FlickrDownloadManager {
    
    static var stack: CoreDataStack = {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return delegate.stack
    }()
    
    /**
     Create Photo objects for a given Pin in a given context.
     
     Searches Flickr for images whose coordinates
     are similar to those of the Pin, and generates Photo objects for a random set of (at most) 21 images. 
     Photo objects are saved in the passed in NSManagedObjectContext with a placeholder image.
     
     - Parameters: 
        - pin: The Pin object that informs the geographic coordinate about which to search for images. New 
                Photo objects will be associated with this pin
        - context: The NSManagedObjectContext in which to save new Photo objects
        - completion: The completion handler to call when all of the new Photos have been created. The error
                        argument will be nil if new images were successfully retrieved. Check for code == 0 for
                        network errors, and code == -1 for the case in which no images exist at that coordinate
     */
    static func downloadImagesForPinAndSaveInContext(pin: Pin, context: NSManagedObjectContext, completion: (NSError?) -> Void){
        
        downloadImagesForCoordinates(Double(pin.latitude!), longitude: Double(pin.longitude!)) { photoData, error in
            
            
            if let error = error {
                completion(error)
            }
            else if photoData?.count == 0 {
                let noPhotosError = NSError(domain: "No images", code: -1, userInfo: nil)
                print (noPhotosError)
                completion(noPhotosError)
            }
            else {
                for photo in photoData! {
                    if let url = photo["url_m"] as? String,
                        let dateTaken = photo["datetaken"] as? String {
                        let dateFormatter = NSDateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        let date = dateFormatter.dateFromString(dateTaken)
                        let _  = Photo(pin: pin, date: date, url: url, context: context)
                    }
                }
                self.stack.save()
                completion(nil)
            }
            
        }
        
    
    }
    
    /**
     Replace the image data stored in a Photo with the data stored at its Flickr URL and 
     save the Photo object in CoreData
     
     - Parameters:
        - photos: An array of Photo objects to update
     */
    static func downloadImagesForPhotos(photos: [Photo]){
        for photo in photos {
            downloadImageWithUrl(photo.url!){ data, error in
                
                if let data = data {
                    photo.imageData = data
                    photo.local = true
                    self.stack.save()
                }
                
            }
        }
    }
    
    
    /**
     Download images from Flickr containing data about images in the region of a given coordinate
     
     - Parameters:
        - coordinate: The coordinate about which to search for images
        - completion: The completion handler to call, returning an image (represented as NSData) or 
     an error to the caller
     
     */
    private static func downloadImagesForCoordinates(latitude: Double, longitude: Double, completion: ([[String:AnyObject]]?, NSError?) -> Void){
        
        getNumPagesForCoordinates(latitude, longitude: longitude){ pages, error in
            
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
                "lat": latitude,
                "lon": longitude,
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
    private static func getNumPagesForCoordinates(latitude: Double, longitude: Double, completion: (Int?, NSError?) -> Void){
        
        Alamofire.request(
            .GET,
            "https://api.flickr.com/services/rest/",
            parameters: ["method": "flickr.photos.search",
                "api_key": "a4ebce9cbae74391014b23471293fb42",
                "lat": latitude,
                "lon": longitude,
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
                completion(photos["pages"] as? Int, nil)
        }
    
    }
    
    /**
     Download an image from Flickr
     
     - Parameters:
        - parameters: A dictionary containing, at least, key-value pairs for farm, server, id, 
     and secret
        - completion: The completion handler to call after an image has been downloaded
     */
     private static func downloadImageWithUrl(url: String, completion: (NSData?, NSError?) -> Void){
        
        
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