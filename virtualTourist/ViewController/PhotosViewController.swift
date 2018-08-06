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
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var NewCollectionButtonOutlet: UIBarButtonItem!
    
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
        let space:CGFloat = 0.5
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)

    }
    @IBOutlet weak var photoCollection: UICollectionView!
    
    @IBAction func newCollectionButton(_ sender: Any) {
        if photosURLArray.count > 21{
            photosURLArray.removeSubrange((0..<22))
            collectionView.reloadData()
        } else{
            photosURLArray.removeAll()
            collectionView.reloadData()
        }
    }
    @IBAction func okeyBackButton(_ sender: Any) {
        photosURLArray.removeAll()
        let mapController = self.storyboard?.instantiateViewController(withIdentifier: "MapVC") as! MapViewController
        mapController.photosURLArray = [String]()
        self.present(mapController, animated: true, completion: nil)
    }
    
    func makeRequest(latitude: Double, longitude: Double){
        //preencher esse metodo com os pares que eu criei na Struct
        
        let methodParameters = [Constants.FlickrParameterKeys.Method:Constants.FlickrParameterValues.SearchPhotosMethod, Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey, Constants.FlickrParameterKeys.Latitude: "\(latitude)", Constants.FlickrParameterKeys.Longitude: "\(longitude)", Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,  Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat, Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback]
        
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
                print("Marcela \(urlm)")
                self.photosURLArray.append(urlm as! String)
            }
        }
        task.resume()
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


extension PhotosViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(21, photosURLArray.count)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoViewCell
        let photoUrlString = photosURLArray[indexPath.row]
        let photoSquareURLstring = URL(string: photoUrlString)
        if let imageData = try? Data(contentsOf: photoSquareURLstring!) {
        cell.photoImage.image = UIImage(data: imageData)
        }
        return cell
    }
}

