//
//  MapViewController.swift
//  virtualTourist
//
//  Created by Marcela Ceneviva Auslenter on 24/07/2018.
//  Copyright © 2018 Marcela Ceneviva Auslenter. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tapPinsDeleteLabel: UILabel!
    @IBOutlet weak var editButtonOutlet: UIBarButtonItem!
    var mapAnnotationDictionary: Dictionary = [MKPointAnnotation: Map]()
    var isOnEditMode = false
    var numberOfPage = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tapPinsDeleteLabel.isHidden = true
        
        mapView.delegate = self
        
        //check if there's LatLon saved on userDefaults
        let latitude = UserDefaults.standard.double(forKey: "latitude")
        let longitude = UserDefaults.standard.double(forKey: "longitude")
        print("MARCELA: LATIDUDE \(latitude) , LONGITUDE \(longitude)")
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        //check if zoom is saved on userDefaults
        let latitudeDelta = UserDefaults.standard.double(forKey: "latitudeDelta")
        let longitudeDelta = UserDefaults.standard.double(forKey: "longitudeDelta")
        let spam = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        //create MKregion and set to mapview
        mapView.setRegion(MKCoordinateRegion(center: center, span: spam), animated: true)
        print("MARCELA : LATITUDE E LONGITUDE != DE 0 \(latitude) e \(longitude)")
        
        let fetchRequest: NSFetchRequest<Map> = Map.fetchRequest()
        do {
            let locations = try DataBaseController.persistentContainer.viewContext.fetch(fetchRequest)
            for map in locations{
                let annotation = MKPointAnnotation()
                annotation.title = "title"
                annotation.coordinate.latitude = map.latitude
                annotation.coordinate.longitude = map.longitude
                mapAnnotationDictionary[annotation] = map
                mapView.addAnnotation(annotation)
            }
        } catch {
            print("Fetch failed")
        }
        //        print("MARCELA DICTIONARY: \(mapAnnotationDictionary)")
        
        
        let uilgr = UILongPressGestureRecognizer(target: self, action: #selector(addPin(gestureRecognizer:)))
        uilgr.minimumPressDuration = 1.0
        uilgr.delegate = self
        mapView.addGestureRecognizer(uilgr)
        
    }
    
    //MARK: UIGestureRecognizerDelegate methods
    
    @objc func addPin(gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == .ended{
            if !isOnEditMode{
                //obtaining new coordinates
                let touchPoint = gestureRecognizer.location(in: mapView)
                let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
                
                //creating annotations and adding to map
                let annotation = MKPointAnnotation()
                annotation.title = "title"
                annotation.coordinate = newCoordinates
                mapView.addAnnotation(annotation)
                
                //            init managedObject and add annotations to DataBase
                let mapLocation = Map(context: DataBaseController.persistentContainer
                    .viewContext)
                mapLocation.latitude = newCoordinates.latitude
                mapLocation.longitude = newCoordinates.longitude
                
                DataBaseController.saveContext()
            }
        }
    }
    
    //MARK: MKMapViewDelegate methods
    
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
    
    @IBAction func editPinsButton(_ sender: Any) {
        isOnEditMode = !isOnEditMode
        print("MARCELA: \(isOnEditMode)")
        if isOnEditMode{
            tapPinsDeleteLabel.isHidden = false
            editButtonOutlet.title = "Done"
        }else{
            tapPinsDeleteLabel.isHidden = true
            editButtonOutlet.title = "Edit"
        }
    }
    //essa funcao só será chamada se o edit button for chamado
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation{
            if isOnEditMode{
                //delete annotation
                mapView.removeAnnotation(annotation)
                if let mapForAnnotation = mapAnnotationDictionary[annotation as! MKPointAnnotation]{
                    DataBaseController.persistentContainer.viewContext.delete(mapForAnnotation)
                    DataBaseController.saveContext()
                    mapAnnotationDictionary[annotation as! MKPointAnnotation] = nil
                }
            }else{
                //faz o request pro flicker e troca a VC
                UserDefaults.standard.set(mapView.centerCoordinate.latitude, forKey: "latitude")
                UserDefaults.standard.set(mapView.centerCoordinate.longitude, forKey: "longitude")
                UserDefaults.standard.set(mapView.region.span.latitudeDelta, forKey: "latitudeDelta")
                UserDefaults.standard.set(mapView.region.span.longitudeDelta, forKey: "longitudeDelta")
                FlikrRequestManager.sharedInstance().getPhotos(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, numberOfPage: numberOfPage){(success, photosURLArray, totalNumberOfPages, error) in
                    performUIUpdatesOnMain {
                        if success{
                            let controller = self.storyboard?.instantiateViewController(withIdentifier: "PhotosVC") as! PhotosViewController
                            controller.annotation = annotation as? MKPointAnnotation
                            controller.mapRegion = self.mapView.region
                            if let photosURLArray = photosURLArray {
                                if let totalNumberOfPages = totalNumberOfPages{
                                    controller.photosURLArray = photosURLArray
                                    controller.totalNumberOfPages = totalNumberOfPages
                                }
                            }
                            self.present(controller, animated: true, completion: nil)
                        }else{
                            //handle error
                        }
                    }
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.region = mapView.region
    }
    
}


