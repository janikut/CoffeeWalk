//
//  MapViewController.swift
//  NearbyCoffee
//
//  Created by Janina Kutyn on 2017-03-10.
//  Copyright © 2017 JaninaKutyn. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    /// Radius options, expressed in meters.
    enum Radius: Int {
        case `default` = 500
        case near = 200
        case far = 1000
    }
    
    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.frame = view.bounds
        mapView.delegate = self
        mapView.showsUserLocation = true
        view.addSubview(mapView)
        
        configureNavigationItem()
    }

    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        location = userLocation.location
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let annotationView = MKPinAnnotationView()

        // We are using pin color to give the user visual indication of the distance.
        let pinColor: UIColor
        switch radius {
        case .default:
            pinColor = Theme.accentColor1
        case .far:
            pinColor = Theme.accentColor2
        case .near:
            pinColor = Theme.accentColor3
        }
        annotationView.pinTintColor = pinColor
        annotationView.canShowCallout = true
        return annotationView
    }
    
    // MARK: - Private
    
    private let mapView = MKMapView()
    private let venueManager = VenueRequestManager()
    private var location: CLLocation? {
        didSet {
            resetMapRegion()
            updateVenues()
        }
    }
    private var radius: Radius = .default {
        didSet {
            resetMapRegion()
            
            if radius != oldValue {
                updateRightBarButtonTitle()
                updateVenues()
            }
        }
    }
    
    private func configureNavigationItem() {
        let logo = UIImage(named: "Logo")?.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: logo)
        navigationItem.titleView = imageView
        
        let recenterIcon = UIImage(named: "RecenterIcon")?.withRenderingMode(.alwaysTemplate)
        let leftBarButtonItem = UIBarButtonItem.init(image: recenterIcon, style: .plain, target: self, action: #selector(resetMapRegion))
        navigationItem.leftBarButtonItem = leftBarButtonItem
        
        let rightBarButtonItem = UIBarButtonItem.init(title: nil, style: .plain, target: self, action: #selector(showRadiusPicker))
        navigationItem.rightBarButtonItem = rightBarButtonItem
        updateRightBarButtonTitle()
    }
    
    @objc private func resetMapRegion() {
        guard let location = location else {
            return
        }
        
        // The map resets to display the user in the center with the region fitting the currently selected radius.
        let diameter = CLLocationDistance(radius.rawValue) * 2
        var region = MKCoordinateRegion.init(center: location.coordinate, latitudinalMeters: diameter, longitudinalMeters: diameter)
        region = mapView.regionThatFits(region)
        mapView.setRegion(region, animated: true)
    }
    
    private func updateVenues() {
        guard let location = location else {
            return
        }
        
        // Force removal of all annotations before requesting new ones.
        clearMap()
        
        // Could extend the implementation by having a more prominent loading indicator.
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        venueManager.getVenues(forLocation: location, inRadius: radius.rawValue) { [weak self] result in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                switch result {
                case .success(let venues):
                    self?.plot(venues: venues)
                case .failure(_):
                    self?.showErrorMessage()
                case .canceled():
                    break
                }
            }
        }
    }
    
    private func updateRightBarButtonTitle() {
        // Right bar button item displays the currently selected radius, expressed in minutes.
        navigationItem.rightBarButtonItem?.title = shortDescription(forRadius: radius)
    }
    
    private func clearMap() {
        mapView.removeAnnotations(mapView.annotations)
    }
    
    private func plot(venues: [Venue]) {
        var annotations: [MKAnnotation] = []
        
        // Just using out of the box MKPointAnnotation,
        // but the implementation could be extended to show more sophisticated callouts.
        // It would be nice to also show website or other contact details.
        for venue in venues {
            let annotation = MKPointAnnotation()
            annotation.coordinate = venue.location.coordinate
            annotation.title = venue.name
            annotation.subtitle = venue.address
            
            annotations.append(annotation)
        }
        
        mapView.addAnnotations(annotations)
    }

    /// Generic message for network errors.
    private func showErrorMessage() {
        let alertController = UIAlertController(title: "Oops", message: "Something went wrong.", preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(dismissAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func showRadiusPicker() {
        // For this assignment I chose to go with preset distances.
        // Perhaps the user would find it more useful to use a slider.
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let dismissAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(dismissAction)
        
        let smallerRadiusAction = UIAlertAction(title: longDescriptionForDistance(forRadius: .near), style: .default) { [weak self] _ in
            self?.radius = .near
        }
        alertController.addAction(smallerRadiusAction)
        
        let defaultRadiusAction = UIAlertAction(title: longDescriptionForDistance(forRadius: .default), style: .default) { [weak self] _ in
            self?.radius = .default
        }
        alertController.addAction(defaultRadiusAction)
        
        let largerRadiusAction = UIAlertAction(title: longDescriptionForDistance(forRadius: .far), style: .default) { [weak self] _ in
            self?.radius = .far
        }
        alertController.addAction(largerRadiusAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    /// For use by the right bar button item.
    private func shortDescription(forRadius aRadius: Radius) -> String {
        let minutes = Utils.minutesToWalk(meters: aRadius.rawValue)
        return "\(minutes) min"
    }
    
    /// For use by the radius picker.
    private func longDescriptionForDistance(forRadius aRadius: Radius) -> String {
        let minutes = Utils.minutesToWalk(meters: aRadius.rawValue)
        return "\(minutes) minute walk"
    }

}

