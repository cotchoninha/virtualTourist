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
    var annotations = [MKPointAnnotation]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //check if there's LatLon saved on userDefaults
        let latitude = UserDefaults.standard.double(forKey: "latitude")
        let longitude = UserDefaults.standard.double(forKey: "longitude")
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        //check if zoom is saved on userDefaults
        let latitudeDelta = UserDefaults.standard.double(forKey: "latitudeDelta")
        let longitudeDelta = UserDefaults.standard.double(forKey: "longitudeDelta")
        let spam = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        //create MKregion and set to mapview
        mapView.setRegion(MKCoordinateRegion(center: center, span: spam), animated: true)
        print("MARCELA : LATITUDE E LONGITUDE != DE 0 \(latitude) e \(longitude)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        let fetchRequest: NSFetchRequest<Map> = Map.fetchRequest()
        //        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        //        fetchRequest.sortDescriptors = [sortDescriptor]
        do {
            let locations = try DataBaseController.persistentContainer.viewContext.fetch(fetchRequest)
            for item in locations{
                let annotation = MKPointAnnotation()
                annotation.coordinate.latitude = item.latitude
                annotation.coordinate.longitude = item.longitude
                annotations.append(annotation)
                mapView.addAnnotations(annotations)
            }
        } catch {
            print("Fetch failed")
        }
        
        let uilgr = UILongPressGestureRecognizer(target: self, action: #selector(addPin(gestureRecognizer:)))
        //TODO: VER PQ ESTÁ SALVANDO VÁRIAS VEZES
        uilgr.minimumPressDuration = 1.0
        uilgr.delegate = self
        mapView.addGestureRecognizer(uilgr)
    }
    
    
    
    @objc func addPin(gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == .ended{
            //obtaining new coordinates
            let touchPoint = gestureRecognizer.location(in: mapView)
            let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            //creating annotations and adding to map
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            annotations.append(annotation)
            mapView.addAnnotations(annotations)
            
            //init managedObject and add annotations to DataBase
            let mapLocation = Map(context: DataBaseController.persistentContainer
                .viewContext)
            mapLocation.latitude = newCoordinates.latitude
            mapLocation.longitude = newCoordinates.longitude
            
            try? DataBaseController.saveContext()
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        //code for when you click in a pin
        //instanciar uma collection view
        //empurrar o mapa pra cima igual faz com o teclado
        
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.region = mapView.region
    }
    
}
