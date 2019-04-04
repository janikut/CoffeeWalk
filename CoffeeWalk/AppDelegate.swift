//
//  AppDelegate.swift
//  CoffeeWalk
//
//  Created by Janina Kutyn on 2017-03-14.
//  Copyright © 2017 JaninaKutyn. All rights reserved.
//

import UIKit
import MapKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let locationManager = CLLocationManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // The location manager is used to request permission to access user location.
        // For the purposes of this assignment, we assume that the user will click Allow.
        locationManager.requestWhenInUseAuthorization()
        
        let viewController = MapViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        window?.tintColor = Theme.tintColor
        
        return true
    }
}

