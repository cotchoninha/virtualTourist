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
//        let fetchRequest: NSFetchRequest<Map> = Map.fetchRequest()
//        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
//        fetchRequest.sortDescriptors = [sortDescriptor]
//        do {
//            let map = try DataBaseController.persistentContainer.viewContext.fetch(fetchRequest)
//            mapView.addAnnotations(CLLocationCoordinate2D(latitude: map[0].latitude, longitude: map[0].longitude))
//            print("Got")
//
//        } catch {
//            print("Fetch failed")
//        }
//
        let uilgr = UILongPressGestureRecognizer(target: self, action: #selector(addPin(gestureRecognizer:)))
        uilgr.minimumPressDuration = 1.0
        uilgr.delegate = self
        mapView.addGestureRecognizer(uilgr)
    }
    
  
    
    @objc func addPin(gestureRecognizer:UIGestureRecognizer){
        let touchPoint = gestureRecognizer.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
//        let mapLocation = Map(context: DataBaseController.persistentContainer
//        .viewContext)
//        mapLocation.latitude = mapView.centerCoordinate.latitude
//        mapLocation.longitude = mapView.centerCoordinate.longitude
//        try? DataBaseController.saveContext()
        annotation.coordinate = newCoordinates
        annotations.append(annotation)
        mapView.addAnnotations(annotations)
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


