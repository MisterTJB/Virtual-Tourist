//
//  FlickrDownloadManager.swift
//  Virtual Tourist
//
//  Created by Tim on 21/08/16.
//  Copyright © 2016 Tim. All rights reserved.
//

import Foundation
import Alamofire



class FlickrDownloadManager {
    
    static func downloadImagesForRegion(completion: ([Int]?, NSError?) -> Void){
        let url = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=a4ebce9cbae74391014b23471293fb42&lat=41.292167695422506&lon=174.77189273921775&format=json&nojsoncallback=1"
        
        Alamofire.request(
            .GET,
            "https://api.flickr.com/services/rest/",
            parameters: ["method": "flickr.photos.search",
            "api_key": "a4ebce9cbae74391014b23471293fb42",
            "lat": "41.292167695422506",
            "lon": "174.77189273921775",
            "format": "json",
            "nojsoncallback": "1"],
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
                
                var imageIdentifiers = [Int]()
                for photoData in photo {
                    guard let identifier = photoData["id"] else {
                        completion(nil, NSError(domain: "Tried to access photo with no identifier", code: 0, userInfo: nil))
                        return
                    }
                    
                    guard let identifierInteger = identifier.integerValue else {
                        completion(nil, NSError(domain: "Couldn't convert identifier to integer", code: 0, userInfo: nil))
                        return
                    }
                
                    imageIdentifiers.append(identifierInteger)
                }
                
                completion(imageIdentifiers, nil)
        }
    
    }


}

struct Constants {
    
    // MARK: Flickr
    struct Flickr {
        static let APIScheme = "https"
        static let APIHost = "api.flickr.com"
        static let APIPath = "/services/rest"
        
        static let SearchBBoxHalfWidth = 1.0
        static let SearchBBoxHalfHeight = 1.0
        static let SearchLatRange = (-90.0, 90.0)
        static let SearchLonRange = (-180.0, 180.0)
    }
    
    // MARK: Flickr Parameter Keys
    struct FlickrParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let GalleryID = "gallery_id"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let SafeSearch = "safe_search"
        static let Text = "text"
        static let BoundingBox = "bbox"
        static let Page = "page"
    }
    
    // MARK: Flickr Parameter Values
    struct FlickrParameterValues {
        static let SearchMethod = "flickr.photos.search"
        static let APIKey = "a4ebce9cbae74391014b23471293fb42"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1" /* 1 means "yes" */
        static let GalleryPhotosMethod = "flickr.galleries.getPhotos"
        static let GalleryID = "5704-72157622566655097"
        static let MediumURL = "url_m"
        static let UseSafeSearch = "1"
    }
    
    // MARK: Flickr Response Keys
    struct FlickrResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Title = "title"
        static let MediumURL = "url_m"
        static let Pages = "pages"
        static let Total = "total"
    }
    
    // MARK: Flickr Response Values
    struct FlickrResponseValues {
        static let OKStatus = "ok"
    }
}