//
//  FlickerPhotosViewController.swift
//  UICollectionViewGettingStarted
//
//  Created by ALIREZA TABRIZI on 12/3/16.
//  Copyright © 2016 AR-T.com, Inc. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class FlickerPhotosViewController: UICollectionViewController {

    fileprivate let reuseIdentifier = "FlickerCell"
    fileprivate let sectionInset = UIEdgeInsetsMake(50.0, 20.0, 50.0, 20.0)
    fileprivate var searches = [FlickrSearchResults]()
    fileprivate let flicker = Flickr()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    
}

//MARK: - Private
///photoForIndexPath is a convenience method that will get a specific photo related to an index path in your collection view. You’re going to access a photo for a specific index path a lot, and you don’t want to repeat code.
private extension FlickerPhotosViewController{
    func photoForIndexPath(_ indexPath: IndexPath) -> FlickrPhoto {
        return searches[(indexPath as NSIndexPath).section].searchResults[(indexPath as NSIndexPath).row]
    }
}

extension FlickerPhotosViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // 1 - After adding an activity view, use the Flickr wrapper class I provided to search Flickr for photos that match the given search term asynchronously. When the search completes, the completion block will be called with a the result set of FlickrPhoto objects, and an error (if there was one)
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        textField.addSubview(activityIndicator)
        activityIndicator.frame = textField.bounds
        activityIndicator.stopAnimating()
        
        flicker.searchFlickrForTerm(textField.text!) { (results, error) in
            
            activityIndicator.removeFromSuperview()
            
            if let error = error {
                // 2 - Log any errors to the console. Obviously, in a production application you would want to display these errors to the user.
                print("Error searching: \(error)")
                return
            }
            
            if let results = results {
                // 3 - The results get logged and added to the front of the searches array
                print("Found \(results.searchResults.count) matching \(results.searchTerm)")
                self.searches.insert(results, at: 0)
                
                //4 - At this stage, you have new data and need to refresh the UI. You’re using the reloadData() method, which works just like it does in a table view.
               // self.collectionView?.reloadData()
            }
        }
        
        textField.text = nil
        textField.resignFirstResponder()
        return true
    }
}
