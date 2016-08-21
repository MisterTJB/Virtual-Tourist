//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Tim on 3/06/16.
//  Copyright © 2016 Tim. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController : UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    // TODO Create photos using identifiers and managed object context
    // i.e. call some function in FlickrDownloadManager, let the callback
    // create a new Photo(id, imageData), then set its Pin to the current 
    // Pin.
    // Also, when that pin is created, display it in the collection view 
    // somehow
    
    override func viewDidLoad() {
        
        // TODO If FetchResult is empty, download images. Else, load in data
        FlickrDownloadManager.downloadImagesForRegion { data, error in
            
            if let error = error {
                print (error.domain)
            } else {
                print(data)
            }
        }
    }
    
    @IBAction func newCollection(sender: UIBarButtonItem) {
        // TODO The Photo Album view has a button that initiates the download 
        // of a new album, replacing theimages in the photo album with a new 
        // set from Flickr.
    }
}