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
import CoreData

class PhotosViewController: UIViewController{
    
    var annotation: MKPointAnnotation?
    var mapRegion: MKCoordinateRegion?
    var imagesArray = [ImageStruct]()
    var downloadedImages = [UIImage?]()
    var isOnDeleteMode = false
    var indexOfPhotosToDelete = [IndexPath]()
    var numberOfThePage = 1
    var totalNumberOfPages: Int?
    private var fetchedRC: NSFetchedResultsController<Image>!
    var pin: Pin!
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var photoCollection: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("MARCELA início de viewDidLoad")
        
        self.mapView.isZoomEnabled = false
        self.mapView.isScrollEnabled = false
        self.mapView.isUserInteractionEnabled = false
        if let annotation = annotation, let region = mapRegion{
            mapView.addAnnotation(annotation)
            mapView.setRegion(region, animated: true)
        }
        //Collection Layout
        //TODO: remover linha abaixo depois de testar com CollectionView
        collectionView.delegate = self
        let space:CGFloat = 0.2
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
        collectionView?.allowsMultipleSelection = true
        
    }
    
    fileprivate func fetchImagesInDB() {
        let request: NSFetchRequest<Image> = Image.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(Image.url), ascending: true)]
        request.predicate = NSPredicate(format: "pin = %@", pin)
        do {
            fetchedRC = NSFetchedResultsController(fetchRequest: request, managedObjectContext: DataBaseController.getContext(), sectionNameKeyPath: nil, cacheName: nil)
            try fetchedRC.performFetch()
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("MARCELA início de viewWillAppear")
        fetchImagesInDB()
        if let fetchedImages = fetchedRC.fetchedObjects{
            if !fetchedImages.isEmpty{
                collectionView.reloadData()
            }else{
                if let coordinates = annotation?.coordinate{
                    FlikrRequestManager.sharedInstance().getPhotos(latitude: coordinates.latitude, longitude: coordinates.longitude, numberOfPage: numberOfThePage) { (success, imagesArray, totalNumberOfPages, error) in
                        if success{
                            self.totalNumberOfPages = totalNumberOfPages
                            self.numberOfThePage += 1
                            if let imagesArray = imagesArray {
                                if imagesArray.count != 0{
                                    for i in 0..<imagesArray.count{
                                        //criar o MO e salvar os attributes url e pin
                                        let image = Image(context: DataBaseController.getContext())
                                        image.url = imagesArray[i].url
                                        image.pin = self.pin
                                    }
                                    //salva no DB
                                    DataBaseController.saveContext()
                                    //pega novamente as imagens com URL, pin e imageData = nil
                                    self.fetchImagesInDB()
                                    
                                    //atualiza a collection view para aparecerem os activity indicators
                                    performUIUpdatesOnMain {
                                        self.collectionView.reloadData()
                                    }
                                }else{
                                    performUIUpdatesOnMain {
                                        self.createNoImagesLabel()
                                    }
                                }
                            }
                        }
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
                
                completionHandlerOnImageDownloaded(imageData, nil)
            }
            task.resume()
        }
        
        
    }
    
    fileprivate func createNoImagesLabel() {
        collectionView.isHidden = true
        let label = UILabel()
        label.frame = CGRect(x: 0, y: 526, width: self.view.frame.width, height: 50)
        label.text = "This pin has no images."
        label.textAlignment = .center
        label.textColor = UIColor.black
        label.backgroundColor = UIColor.white
        label.font = UIFont(name: "Arial", size: 26)
        self.view.addSubview(label)
        newCollectionButton.isEnabled = false
    }
    
    
    func resetAllRecords(){
        if let objects = fetchedRC.fetchedObjects{
            for object in objects {
                DataBaseController.getContext().delete(object)
            }
            DataBaseController.saveContext()
            fetchImagesInDB()
            print("MARCELA: FETCHRC.COUNT DENTRO DE resetAllRecords = \(fetchedRC.fetchedObjects?.count)")
            collectionView.reloadData()
        }
    }
    
    @IBAction func getNewCollectionOfImages(_ sender: Any) {
        newCollectionButton.isEnabled = false
        if isOnDeleteMode{
            if let selectedItems = collectionView.indexPathsForSelectedItems{
                let reversedIndexes = selectedItems.sorted().reversed()
                for index in reversedIndexes{
                    let objectToDelete = fetchedRC.object(at: index)
                    DataBaseController.getContext().delete(objectToDelete)
                }
                DataBaseController.saveContext()
                fetchImagesInDB()
                collectionView.deleteItems(at: selectedItems)
            }
            indexOfPhotosToDelete.removeAll()
            newCollectionButton.title = "New Collection"
            newCollectionButton.isEnabled = true
            isOnDeleteMode = false
        }else{
            if totalNumberOfPages == nil || numberOfThePage <= totalNumberOfPages!{
//                let deleteIndexPath = IndexPath(item: ((fetchedRC.fetchedObjects?.count)! - 1), section: 0)
//                collectionView.deleteItems(at: [deleteIndexPath])
                resetAllRecords()
                if let latitude = annotation?.coordinate.latitude, let longitude = annotation?.coordinate.longitude{
                    FlikrRequestManager.sharedInstance().getPhotos(latitude: latitude, longitude: longitude, numberOfPage: numberOfThePage) { (success, imagesArray, totalNumberOfPages, error) in
                        if success{
                            self.totalNumberOfPages = totalNumberOfPages
                            self.numberOfThePage += 1
                            if let imagesArray = imagesArray {
                                if imagesArray.count != 0{
                                    for i in 0..<imagesArray.count{
                                        //criar o MO e salvar os attributes url e pin
                                        let image = Image(context: DataBaseController.getContext())
                                        image.url = imagesArray[i].url
                                        image.pin = self.pin
                                    }
                                    //salva no DB
                                    DataBaseController.saveContext()
                                    //pega novamente as imagens com URL, pin e imageData = nil
                                    self.fetchImagesInDB()

                                    //atualiza a collection view para aparecerem os activity indicators
                                    performUIUpdatesOnMain {
                                        self.collectionView.reloadData()
                                    }
                                }else{
                                    performUIUpdatesOnMain {
                                        self.createNoImagesLabel()
                                    }
                                }
                            }
                        }else{
                            //handle error
                        }
                    }
                }
            }else{
                //remover todas as imagens e chamar reloadData()
                self.createNoImagesLabel()
                //mostro a label no images
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
        print("MARCELA: numberOfItemsInSection FETCHRC.COUNT = \(fetchedRC.fetchedObjects?.count)")
        return fetchedRC.fetchedObjects?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("MARCELA início de cellForItem")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoViewCell
       
        let fetchedObject = fetchedRC.object(at: indexPath)
        
        if fetchedObject.imageData == nil{
            print("MARCELA fetchedObject.imageData == nil")
            cell.photoImage.image = nil
            cell.activityIndicator.startAnimating()
            if let url = fetchedObject.url{
                print("MARCELA inicio download da imagem")
                self.downloadImage(url: url) {(imageData, error) in
                    guard error == nil else{
                        print("MARCELA couldn't download data: \(error)")
                        return
                    }
                    print("MARCELA fim download da imagem")
                    if let imageDataDownloaded = imageData{
                        fetchedObject.imageData = imageDataDownloaded
                    }
                    DataBaseController.saveContext()
                    print("MARCELA atualiza DB")
                    performUIUpdatesOnMain {
                        collectionView.reloadItems(at: [indexPath])
                        print("MARCELA reload collectionView ")
                    }
                }
            }
        }else{
            cell.activityIndicator.stopAnimating()
            cell.activityIndicator.hidesWhenStopped = true
            
            if let imageData = fetchedRC.object(at: indexPath).imageData{
                print("MARCELA exibe imagem do MnagedObject")
                cell.photoImage.image = UIImage(data: imageData)
            }
            
            newCollectionButton.isEnabled = true
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        isOnDeleteMode = true
        newCollectionButton.title = "Remove Selected Pictures"
        indexOfPhotosToDelete.append(indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let photoSelected = indexOfPhotosToDelete.index(of: indexPath){
            indexOfPhotosToDelete.remove(at: photoSelected)
        }
//            indexOfPhotosToDelete.filter { $0 != indexPath}
        if indexOfPhotosToDelete.isEmpty{
            newCollectionButton.title = "New Collection"
        }
    }
}

