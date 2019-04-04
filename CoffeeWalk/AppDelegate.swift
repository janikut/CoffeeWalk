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
        // Since authorization is needed for the app to function, we ask for permission now.
        // TODO: We assume that the user grants permission; handle the case when user does not.
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

