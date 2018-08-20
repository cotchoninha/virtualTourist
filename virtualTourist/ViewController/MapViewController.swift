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
    var mapAnnotationDictionary: Dictionary = [MKPointAnnotation: Pin]()
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
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        do {
            let fetchedPins = try DataBaseController.getContext().fetch(fetchRequest)
            for pin in fetchedPins{
                let annotation = MKPointAnnotation()
                annotation.title = "title"
                annotation.coordinate.latitude = pin.latitude
                annotation.coordinate.longitude = pin.longitude
                mapAnnotationDictionary[annotation] = pin
                mapView.addAnnotation(annotation)
            }
        } catch {
            print("Fetch failed")
        }
        
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
                let pin = Pin(context: DataBaseController.persistentContainer
                    .viewContext)
                pin.latitude = newCoordinates.latitude
                pin.longitude = newCoordinates.longitude
                mapAnnotationDictionary[annotation] = pin
                
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation as? MKPointAnnotation{
            if isOnEditMode{
                //delete annotation
                mapView.removeAnnotation(annotation)
                if let mapForAnnotation = mapAnnotationDictionary[annotation]{
                    DataBaseController.getContext().delete(mapForAnnotation)
                    DataBaseController.saveContext()
                    mapAnnotationDictionary[annotation] = nil
                }
            }else{
                UserDefaults.standard.set(mapView.centerCoordinate.latitude, forKey: "latitude")
                UserDefaults.standard.set(mapView.centerCoordinate.longitude, forKey: "longitude")
                UserDefaults.standard.set(mapView.region.span.latitudeDelta, forKey: "latitudeDelta")
                UserDefaults.standard.set(mapView.region.span.longitudeDelta, forKey: "longitudeDelta")
                let controller = self.storyboard?.instantiateViewController(withIdentifier: "PhotosVC") as! PhotosViewController
                controller.annotation = annotation
                controller.mapRegion = self.mapView.region
                controller.pin = mapAnnotationDictionary[annotation]
                self.present(controller, animated: true, completion: nil)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.region = mapView.region
    }
    
}


