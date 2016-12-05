import UIKit

final class FlickerPhotosViewController: UICollectionViewController {
    
    // MARK: - Properties
    fileprivate let reuseIdentifier = "FlickrCell"
    fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    
    fileprivate var searches = [FlickrSearchResults]()
    fileprivate let flickr = Flickr()
    fileprivate let itemsPerRow: CGFloat = 3
    
    fileprivate var selectedPhotos = [FlickrPhoto]()
    fileprivate let shareTextLabel = UILabel()
    
    // 1 - largePhotoIndexPath is an optional that will hold the index path of the tapped photo, if there is one.
    var largePhotoIndexPath: IndexPath? {
        didSet {
            // 2 - Whenever this property gets updated, the collection view needs to be updated. a didSet property observer is the safest place to manage this. There may be two cells that need reloading, if the user has tapped one cell then another, or just one if the user has tapped the first cell, then tapped it again to shrink.
            var indexPaths = [IndexPath]()
            if let largePhotoIndexPath = largePhotoIndexPath {
                indexPaths.append(largePhotoIndexPath)
            }
            if let oldValue = oldValue {
                indexPaths.append(oldValue)
            }
            
            // 3 - performBatchUpdates will animate any changes to the collection view performed inside the block. You want it to reload the affected cells.
            collectionView?.performBatchUpdates({ 
                self.collectionView?.reloadItems(at: indexPaths)
            }) { completed in
                
                // 4 - Once the animated update has finished, it’s a nice touch to scroll the enlarged cell to the middle of the screen
                if let largePhotoIndexPath = self.largePhotoIndexPath{
                    self.collectionView?.scrollToItem(at: largePhotoIndexPath as IndexPath, at: .centeredVertically, animated: true)
                }
            
            }
            
        }
    }
    
    ///Belo and above property is how you do a property observer
    // sharing is a Bool with another property observer, similar to largePhotoIndexPath above
    var sharing : Bool = false {
        didSet{
            // you toggle the multiple selection status of the collection view, clear any existing selection and empty the selected photos array.
            collectionView?.allowsMultipleSelection = sharing
            collectionView?.selectItem(at: nil, animated: true, scrollPosition: UICollectionViewScrollPosition())
            selectedPhotos.removeAll(keepingCapacity: false)
            
            // You also update the bar button items to include and update the shareTextLabel.
            guard let shareButton = self.navigationItem.rightBarButtonItems?.first else {
                return
            }
            
            guard sharing else {
                navigationItem.setRightBarButtonItems([shareButton], animated: true)
                return
            }
            
            if let _ = largePhotoIndexPath {
                largePhotoIndexPath = nil
            }
            
            
            updateSharedPhotoCount()
            let sharingDetailItem = UIBarButtonItem(customView: shareTextLabel)
            navigationItem.setRightBarButtonItems([shareButton, sharingDetailItem], animated: true)
        }
    }
    
    //At the moment, all this method does is some checking to make sure the user has actually searched for something, and has selected photos to share.
    @IBAction func share(_ sender: UIBarButtonItem) {
        guard !searches.isEmpty else {
            return
        }
        
        guard !selectedPhotos.isEmpty else {
            sharing = !sharing
            return
        }
        guard sharing else {
            return
        }
        //TODO actually sharing photos!
    }
}

// MARK: - Private
private extension FlickerPhotosViewController {
    func photoForIndexPath(_ indexPath: IndexPath) -> FlickrPhoto {
        return searches[(indexPath as NSIndexPath).section].searchResults[(indexPath as NSIndexPath).row]
    }
    
    func updateSharedPhotoCount() {
        shareTextLabel.textColor = themeColor
        shareTextLabel.text = "\(selectedPhotos.count) photos selected"
        shareTextLabel.sizeToFit()
    }
}



extension FlickerPhotosViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // 1
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        textField.addSubview(activityIndicator)
        activityIndicator.frame = textField.bounds
        activityIndicator.startAnimating()
        
        flickr.searchFlickrForTerm(textField.text!) {
            results, error in
            
            
            activityIndicator.removeFromSuperview()
            
            
            if let error = error {
                // 2
                print("Error searching : \(error)")
                return
            }
            
            if let results = results {
                // 3
                print("Found \(results.searchResults.count) matching \(results.searchTerm)")
                self.searches.insert(results, at: 0)
                
                // 4
                self.collectionView?.reloadData()
            }
        }
        
        textField.text = nil
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - UICollectionViewDataSource
extension FlickerPhotosViewController {
    //1
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return searches.count
    }
    
    //2
    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return searches[section].searchResults.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        // 1 - The kind parameter is supplied by the layout object and indicates which sort of supplementary view is being asked for
        switch kind {
        // 2 - UICollectionElementKindSectionHeader is a supplementary view kind belonging to the flow layout. By checking that box in the storyboard to add a section header, you told the flow layout that it needs to start asking for these views. There is also a UICollectionElementKindSectionFooter, which you’re not currently using. If you don’t use the flow layout, you don’t get header and footer views for free like this
        case UICollectionElementKindSectionHeader:
            // 3 - The header view is dequeued using the identifier added in the storyboard. This works just like cell dequeuing. The label’s text is then set to the relevant search term
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FlickerPhotoHeaderView", for: indexPath) as! FlickerPhotoHeaderView
            headerView.label.text = searches[(indexPath as NSIndexPath).section].searchTerm
            return headerView
            
        default:
            // 4 - An assert is placed here to make it clear to other developers (including future you!) that you’re not expecting to be asked for anything other than a header view
            assert(false, "Unexpected elemnd kind")
        }
    }

    
    //3
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // 1 -
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                                         for: indexPath) as! FlickerPhotoCell
        // 2 -
        let flickrPhoto = photoForIndexPath(indexPath)
        
        // 3 - Always stop the activity spinner – you could be reusing a cell that was previously loading an image
        cell.activityIndicator.stopAnimating()
        
        // 4 - This part is as before – if you’re not looking at the large photo, just set the thumbnail and return
        guard indexPath == largePhotoIndexPath else {
            cell.imageView.image = flickrPhoto.thumbnail
            return cell
        }
        
        // 5 - If the large image is (Ali added: not loaded) already loaded, set it and return
        guard flickrPhoto.largeImage == nil else {
            cell.imageView.image = flickrPhoto.largeImage
            return cell
        }
        
        // 6 - By this point, you want the large image, but it doesn’t exist yet. Set the thumbnail image and start the spinner going. The thumbnail will stretch until the download is complete
        cell.imageView.image = flickrPhoto.thumbnail
        cell.activityIndicator.startAnimating()
        
        // 7 - Ask for the large image from Flickr. This loads the image asynchronously and has a completion block
        flickrPhoto.loadLargeImage { (loadFlickerPhoto, error) in
            // 8 - The load has finished, so stop the spinner
            cell.activityIndicator.stopAnimating()
            
            // 9 - If there was an error or no photo was loaded, there’s not much you can do.
            guard loadFlickerPhoto.largeImage != nil && error == nil else {
                return
            }
            
            // 10 - Check that the large photo index path hasn’t changed while the download was happening, and retrieve whatever cell is currently in use for that index path (it may not be the original cell, since scrolling could have happened) and set the large image.
            if let cell = collectionView.cellForItem(at: indexPath) as? FlickerPhotoCell, indexPath == self.largePhotoIndexPath {
                cell.imageView.image = loadFlickerPhoto.largeImage
            }
        }
        return cell
    }
}

extension FlickerPhotosViewController : UICollectionViewDelegateFlowLayout {
    //1
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath == largePhotoIndexPath {
            let flickerPhoto = photoForIndexPath(indexPath)
            var size = collectionView.bounds.size
            size.height -= topLayoutGuide.length
            size.height -= (sectionInsets.top + sectionInsets.right)
            size.width -= (sectionInsets.left + sectionInsets.right)
            return flickerPhoto.sizeToFillWidthOfSize(size)
        }
        
        //2
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    //3
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    // 4
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

// MARK: - UICollectionViewDelegate
extension FlickerPhotosViewController{

    
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
    
        // This will allow selection in sharing mode.
        guard !sharing else {
            return true
        }
        
        // This method is pretty simple. If the tapped cell is already the large photo, set the largePhotoIndexPath property to nil, otherwise set it to the index path the user just tapped. This will then call the property observer you added earlier and cause the collection view to reload the affected cell(s).
        largePhotoIndexPath = largePhotoIndexPath == indexPath ? nil : indexPath
        
        return false
    }
    
    // This method allows adding selected photos to the shared photos array and updates the shareTextLabel.
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard sharing else {
            return
        }
        
        let photo = photoForIndexPath(indexPath)
        selectedPhotos.append(photo)
        updateSharedPhotoCount()
    }
    
    
    // This method removes a photo from the shared photos array and updates the shareTextLabel.
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard sharing else {
            return
        }
        
        let photo = photoForIndexPath(indexPath)
        
        if let index = selectedPhotos.index(of: photo){
            selectedPhotos.remove(at: index)
            updateSharedPhotoCount()
        }
    }
}














