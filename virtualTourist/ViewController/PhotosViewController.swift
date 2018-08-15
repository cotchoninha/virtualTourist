//
//  PhotosViewController.swift
//  virtualTourist
//
//  Created by Marcela Ceneviva Auslenter on 02/08/2018.
//  Copyright © 2018 Marcela Ceneviva Auslenter. All rights reserved.
//
//  quando eu clicar no pin ele abre as ultimas 21 imagens que estavam salvas na imagesArray

import Foundation
import UIKit
import MapKit

class PhotosViewController: UIViewController{
    
    var annotation: MKPointAnnotation?
    var mapRegion: MKCoordinateRegion?
//    var photosURLArray = [String]()
    var imagesArray = [ImageStruct]()
//    var downloadedImages = [UIImage?]()
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
        print("início de viewDidLoad")
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("início de viewWillAppear")
        
        for i in 0..<imagesArray.count{
            downloadImage(url: imagesArray[i].url) {(imageData, error) in
                guard error == nil else{
                    print("couldn't download data: \(error)")
                    return
                }
                if let imageDataDownloaded = imageData{
                self.imagesArray[i].imageData = UIImage(data: imageDataDownloaded)
                    performUIUpdatesOnMain {
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    func downloadImage(url: String, _ completionHandlerOnImageDownloaded: @escaping (_ imageData: Data?, _ error: Error?) -> Void){
        if let photoSquareURLstring = URL(string: url){
            let task = URLSession.shared.dataTask(with: photoSquareURLstring) { (imageData, response, error) in
                func displayError(_ error: String) {
                    print(error)
                    print("URL at time of error: \(url)")
                    completionHandlerOnImageDownloaded(nil, error as? Error)
                }
                
                /* GUARD: Was there an error? */
                guard (error == nil) else {
                    displayError("There was an error with your request: \(error)")
                    return
                }
                
                /* GUARD: Did we get a successful 2XX response? */
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                    displayError("Your request returned a status code other than 2xx!")
                    return
                }
                
                /* GUARD: Was there any data returned? */
                guard let imageData = imageData else {
                    displayError("No data was returned by the request!")
                    return
                }
                
                let imageCoreData = Image(entity: Image.entity(), insertInto: DataBaseController.getContext())
                imageCoreData.imageData = imageData
                imageCoreData.url = url
                DataBaseController.saveContext()
                print("MARCELA: imageCoreData: \(imageCoreData)")
                completionHandlerOnImageDownloaded(imageData, nil)
            }
            task.resume()
        }
        
        
    }
    @IBAction func newCollectionButton(_ sender: Any) {
        if isOnDeleteMode{
            indexOfPhotosToDelete.sort { $0 > $1 }
            for index in indexOfPhotosToDelete{
                imagesArray.remove(at: index)
                
                
//                downloadedImages.remove(at: index)
            }
            indexOfPhotosToDelete.removeAll()
            collectionView.reloadData()
            NewCollectionButtonOutlet.title = "New Collection"
            //precisa atualizar
            isOnDeleteMode = false
        }else{
            //TODO: quando entra aqui ele nao ativa e desativa o activity indicator
            if let latitude = annotation?.coordinate.latitude, let longitude = annotation?.coordinate.longitude{
                FlikrRequestManager.sharedInstance().getPhotos(latitude: latitude, longitude: longitude, numberOfPage: numberOfPage) { (success, imagesArray, totalNumberOfPages, error) in
                    if success{
                        self.imagesArray.removeAll()
                        if let imagesArray = imagesArray {
                            self.imagesArray = imagesArray
                            performUIUpdatesOnMain {
                                for i in 0..<imagesArray.count{
                                    self.downloadImage(url: imagesArray[i].url) {(imageData, error) in
                                        guard error == nil else{
                                            print("couldn't download data: \(error)")
                                            return
                                        }
                                        if let imageDataDownloaded = imageData{
                                            self.imagesArray[i].imageData = UIImage(data: imageDataDownloaded)
                                            performUIUpdatesOnMain {
//                                                self.collectionView.reloadItems(at: [IndexPath(arrayLiteral: i)])
                                                self.collectionView.reloadData()
                                            }
                                        }
                                    }
                                }
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
        imagesArray.removeAll()
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
        print("início de numberOfItemsInSection")
        return imagesArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("início de cellForItem")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoViewCell
        if imagesArray[indexPath.item].imageData == nil{
            print("MARCELA: image data está NIL")
            
            cell.activityIndicator.startAnimating()
        }else{
            cell.activityIndicator.stopAnimating()
            cell.activityIndicator.hidesWhenStopped = true
            print("MARCELA: image data nao está NIL")
            
            cell.photoImage.image = imagesArray[indexPath.item].imageData
        }
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

