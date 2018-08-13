//
//  PhotoViewCell.swift
//  virtualTourist
//
//  Created by Marcela Ceneviva Auslenter on 03/08/2018.
//  Copyright © 2018 Marcela Ceneviva Auslenter. All rights reserved.
//

import Foundation
import UIKit

class PhotoViewCell: UICollectionViewCell {
    
    @IBOutlet weak var photoImage: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override var isSelected: Bool{
        didSet{
            if isSelected{
               photoImage.alpha = 0.2
            }else{
                photoImage.alpha = 1.0
            }
        }
    }
}
