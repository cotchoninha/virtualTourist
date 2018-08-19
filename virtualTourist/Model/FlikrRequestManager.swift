//
//  FlikrRequests.swift
//  virtualTourist
//
//  Created by Marcela Ceneviva Auslenter on 07/08/2018.
//  Copyright © 2018 Marcela Ceneviva Auslenter. All rights reserved.
//

import Foundation
import UIKit
class FlikrRequestManager: NSObject{
    
    //singleton
    class func sharedInstance() -> FlikrRequestManager {
        struct Singleton {
            static var sharedInstance = FlikrRequestManager()
        }
        return Singleton.sharedInstance
    }
    
    func getPhotos(latitude: Double, longitude: Double, numberOfPage: Int, _ completionHandlerForGETPHOTOS: @escaping (_ success: Bool, _ imagesArray: [ImageStruct]?, _ numberOfPagesResult: Int?, _ error: Error?) -> Void) {
        
        let methodParameters = [Constants.FlickrParameterKeys.Method:Constants.FlickrParameterValues.SearchPhotosMethod, Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey, Constants.FlickrParameterKeys.Latitude: "\(latitude)", Constants.FlickrParameterKeys.Longitude: "\(longitude)", Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,  Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat, Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback, Constants.FlickrParameterKeys.Page: String(numberOfPage), Constants.FlickrParameterKeys.Perpage: String(Constants.FlickrParameterValues.NumberPerpage)]
        
        //chama a funcao que monta o metodo e adiciona a APIBaseURL
        let urlString = Constants.Flickr.APIBaseURL + escapedParameters(methodParameters as [String:AnyObject])
        print("MARCELA: URLSTRING \(urlString)")
        let url = URL(string: urlString)!
        let request = URLRequest(url: url)
        let session = URLSession.shared
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            //colocar o botao de NewCollection como disabled
            
            // if an error occurs, print it and re-enable the UI
            func displayError(_ error: String) {
                print(error)
                print("URL at time of error: \(url)")
                completionHandlerForGETPHOTOS(false, nil, nil, error as? Error)
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
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject], let photoArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]], let totalNumberOfPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                displayError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' and '\(Constants.FlickrResponseKeys.Photo)' in \(parsedResult)")
                return
            }
            print("MARCELA NUMBER OF PAGES: \(totalNumberOfPages)")
           
            //use photos inside photoArray
            var imagesArray = [ImageStruct]()
            for file in photoArray{
                guard let urlm = file["url_m"] else{
                    displayError("Cannot find urlm value")
                    return
                }
//                print("Marcela \(urlm) and photoArray.count = \(photoArray.count)")
                imagesArray.append(ImageStruct(url: urlm as! String, imageData: nil))
            }
            completionHandlerForGETPHOTOS(true, imagesArray, totalNumberOfPages, nil)
        }
        task.resume()
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
