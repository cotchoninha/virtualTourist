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
    
    @IBAction func editPinsButton(_ sender: Any) {
        tapPinsDeleteLabel.isHidden = false
        editButtonOutlet.title = "Done"
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("marcel: viewdidload")
        
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
                print("Marcela: item em location \(map)")
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
        print("MARCELA DICTIONARY: \(mapAnnotationDictionary)")
        
        let uilgr = UILongPressGestureRecognizer(target: self, action: #selector(addPin(gestureRecognizer:)))
        uilgr.minimumPressDuration = 1.0
        uilgr.delegate = self
        mapView.addGestureRecognizer(uilgr)
    }
    
    //MARK: UIGestureRecognizerDelegate methods
    
    @objc func addPin(gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == .ended{
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("MARCELA: ENTRA NA FUNCAO QUANDO SELECIONO PIN")
        if let annotation = view.annotation{
            mapView.removeAnnotation(annotation)
            if let mapForAnnotation = mapAnnotationDictionary[annotation as! MKPointAnnotation]{
            DataBaseController.persistentContainer.viewContext.delete(mapForAnnotation)
            DataBaseController.saveContext()
            mapAnnotationDictionary[annotation as! MKPointAnnotation] = nil
            }
            
        }
    }
    
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.region = mapView.region
    }
    
    
}
