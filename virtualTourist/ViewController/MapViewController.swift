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
    var photosURLArray = [String]()
    var numberOfPages = 1
    
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
        if isOnEditMode{
            //delete annotation
            if let annotation = view.annotation{
                mapView.removeAnnotation(annotation)
                if let mapForAnnotation = mapAnnotationDictionary[annotation as! MKPointAnnotation]{
                    DataBaseController.persistentContainer.viewContext.delete(mapForAnnotation)
                    DataBaseController.saveContext()
                    mapAnnotationDictionary[annotation as! MKPointAnnotation] = nil
                }
                
            }
        }else{
            //faz o request pro flicker e troca a VC
            if let annotation = view.annotation{
                let methodParameters = [Constants.FlickrParameterKeys.Method:Constants.FlickrParameterValues.SearchPhotosMethod, Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey, Constants.FlickrParameterKeys.Latitude: "\(annotation.coordinate.latitude)", Constants.FlickrParameterKeys.Longitude: "\(annotation.coordinate.longitude)", Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,  Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat, Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback, Constants.FlickrParameterKeys.Page: String(numberOfPages), Constants.FlickrParameterKeys.Perpage: String(Constants.FlickrParameterValues.NumberPerpage)]
                
                //chama a funcao que monta o metodo e adiciona a APIBaseURL
                let urlString = Constants.Flickr.APIBaseURL + escapedParameters(methodParameters as [String:AnyObject])
                print("MARCELA: URLSTRING \(urlString)")
                let url = URL(string: urlString)!
                let request = URLRequest(url: url)
                let session = URLSession.shared
                
                // create network request
                let task = session.dataTask(with: request) { (data, response, error) in
                    
                    //colocar o botao de NewCollection como disabled
                    
                    // if an error occurs, print it and re-enable the UI
                    func displayError(_ error: String) {
                        print(error)
                        print("URL at time of error: \(url)")
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
                    guard let data = data else {
                        displayError("No data was returned by the request!")
                        return
                    }
                    
                    // parse the data
                    let parsedResult: [String:AnyObject]!
                    do {
                        parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
                    } catch {
                        displayError("Could not parse the data as JSON: '\(data)'")
                        return
                    }
                    
                    /* GUARD: Did Flickr return an error (stat != ok)? */
                    guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                        displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                        return
                    }
                    
                    /* GUARD: Are the "photos" and "photo" keys in our result? */
                    guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject], let photoArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                        displayError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' and '\(Constants.FlickrResponseKeys.Photo)' in \(parsedResult)")
                        return
                    }
                    
                    //use photos inside photoArray
                    for file in photoArray{
                        guard let urlm = file["url_m"] else{
                            displayError("Cannot find urlm value")
                            return
                        }
                        print("Marcela \(urlm) and photoArray.count = \(photoArray.count)")
                        self.photosURLArray.append(urlm as! String)
                    }
                    performUIUpdatesOnMain {
                        let controller = self.storyboard?.instantiateViewController(withIdentifier: "PhotosVC") as! PhotosViewController
                        if let annotation = view.annotation{
                            controller.annotation = annotation as? MKPointAnnotation
                            controller.mapRegion = self.mapView.region
                            controller.photosURLArray = self.photosURLArray
                            self.present(controller, animated: true, completion: nil)
                        }
                    }
                }
                task.resume()
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.region = mapView.region
    }
    
    private func escapedParameters(_ parameters: [String:AnyObject]) -> String {
        
        if parameters.isEmpty {
            return ""
        } else {
            var keyValuePairs = [String]()
            
            for (key, value) in parameters {
                
                // make sure that it is a string value
                let stringValue = "\(value)"
                
                // escape it
                let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                
                // append it
                keyValuePairs.append(key + "=" + "\(escapedValue!)")
                
            }
            
            return "?\(keyValuePairs.joined(separator: "&"))"
        }
    }
}
