//
//  FlickerPhotoCell.swift
//  UICollectionViewGettingStarted
//
//  Created by ALIREZA TABRIZI on 12/3/16.
//  Copyright © 2016 AR-T.com, Inc. All rights reserved.
//

import UIKit

class FlickerPhotoCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
   
    // MARK: - Properties
    override var isSelected: Bool {
        didSet{
            imageView.layer.borderWidth = isSelected ? 10 : 0
        }
    }
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        //imageView.layer.borderWidth = themeColor.cgColor
        isSelected = false
    }
}
