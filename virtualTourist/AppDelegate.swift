//
//  AppDelegate.swift
//  virtualTourist
//
//  Created by Marcela Ceneviva Auslenter on 24/07/2018.
//  Copyright © 2018 Marcela Ceneviva Auslenter. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import MapKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var region: MKCoordinateRegion?
    let defaultLat = 51.507351
    let defaultLon = -0.127758
    let defaultLatDelta = 1.0
    let defaultLonDelta = 1.0



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if !hasLaunchedBefore{
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            UserDefaults.standard.set(defaultLat, forKey: "latitude")
            UserDefaults.standard.set(defaultLon, forKey: "longitude")
            UserDefaults.standard.set(defaultLatDelta, forKey: "latitudeDelta")
            UserDefaults.standard.set(defaultLonDelta, forKey: "longitudeDelta")
        }
        // Override point for customization after application launch.
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        UserDefaults.standard.set((region?.center.latitude ?? defaultLat), forKey: "latitude")
        UserDefaults.standard.set((region?.center.longitude ?? defaultLon), forKey: "longitude")
        UserDefaults.standard.set((region?.span.latitudeDelta ?? defaultLatDelta), forKey: "latitudeDelta")
        UserDefaults.standard.set((region?.span.longitudeDelta ?? defaultLonDelta), forKey: "longitudeDelta")
        print("MARCELA : setando novas lat lon \(region?.center.latitude ?? 0.0) e \(region?.center.longitude ?? 0.0) and Delta = \((region?.span.latitudeDelta ?? 0.0)), \((region?.span.latitudeDelta ?? 0.0))")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.

        DataBaseController.saveContext()
    }

}

