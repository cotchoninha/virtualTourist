//
//  PhotosViewController.swift
//  virtualTourist
//
//  Created by Marcela Ceneviva Auslenter on 02/08/2018.
//  Copyright © 2018 Marcela Ceneviva Auslenter. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class PhotosViewController: UIViewController{
    
    var annotation: MKPointAnnotation?
    var mapRegion: MKCoordinateRegion?
    var photosURLArray = [String]()
    var isOnDeleteMode = false
    var indexOfPhotosToDelete = [Int]()
    var numberOfPage = 2
    var totalNumberOfPages: Int!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var NewCollectionButtonOutlet: UIBarButtonItem!
    @IBOutlet weak var photoCollection: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.isZoomEnabled = false
        self.mapView.isScrollEnabled = false
        self.mapView.isUserInteractionEnabled = false
        if let annotation = annotation, let region = mapRegion{
            mapView.addAnnotation(annotation)
            mapView.setRegion(region, animated: true)
        }
        //Collection Layout
        collectionView.delegate = self
        let space:CGFloat = 0.2
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
        collectionView?.allowsMultipleSelection = true
        
    }
    
    @IBAction func newCollectionButton(_ sender: Any) {
        if isOnDeleteMode{
            indexOfPhotosToDelete.sort { $0 > $1 }
            for index in indexOfPhotosToDelete{
                photosURLArray.remove(at: index)
            }
            indexOfPhotosToDelete.removeAll()
            collectionView.reloadData()
            NewCollectionButtonOutlet.title = "New Collection"
            //precisa atualizar
            isOnDeleteMode = false
        }else{
            if let latitude = annotation?.coordinate.latitude, let longitude = annotation?.coordinate.longitude{
                FlikrRequestManager.sharedInstance().getPhotos(latitude: latitude, longitude: longitude, numberOfPage: numberOfPage) { (success, photosURLarray, totalNumberOfPages, error) in
                    if success{
                        if let photosURLArray = photosURLarray{
                            self.photosURLArray = photosURLArray
                            performUIUpdatesOnMain {
                                self.collectionView.reloadData()
                            }
                        }
                    }else{
                        //handle error
                    }
                }
            }
            if numberOfPage <= totalNumberOfPages{
                numberOfPage += 1
                print("Marcela: \(numberOfPage)")
            }else if numberOfPage > totalNumberOfPages{
                collectionView.isHidden = true
                let label = UILabel()
                label.frame = CGRect(x: 0, y: 526, width: self.view.frame.width, height: 50)
                label.text = "This pin has no images."
                label.textAlignment = .center
                label.textColor = UIColor.black
                label.backgroundColor = UIColor.white
                label.font = UIFont(name: "Arial", size: 26)
                self.view.addSubview(label)
                NewCollectionButtonOutlet.isEnabled = false
                
                //quando passar o numero total de paginas ele tem que parar de fazer o
            }
        }
    }
    
    @IBAction func okeyBackButton(_ sender: Any) {
        photosURLArray.removeAll()
        let mapController = self.storyboard?.instantiateViewController(withIdentifier: "MapVC") as! MapViewController
        self.present(mapController, animated: true, completion: nil)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            pinView!.animatesDrop = true
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
}

extension PhotosViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photosURLArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoViewCell
//        let photoUrlString = photosURLArray[indexPath.row]
//        let photoSquareURLstring = URL(string: photoUrlString)
//        if let imageData = try? Data(contentsOf: photoSquareURLstring!) {
//            cell.photoImage.image = UIImage(data: imageData)
//        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        isOnDeleteMode = true
        NewCollectionButtonOutlet.title = "Remove Selected Pictures"
        indexOfPhotosToDelete.append(indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        indexOfPhotosToDelete = indexOfPhotosToDelete.filter { $0 != indexPath.row}
        if indexOfPhotosToDelete.count == 0{
            NewCollectionButtonOutlet.title = "New Collection"
        }
    }
}

