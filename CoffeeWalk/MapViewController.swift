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
    
    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        configureMapView()
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
        
        let annotationIdentifier = "AnnotationIdentifier"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MKPinAnnotationView
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView()
        }

        let pinColor: UIColor
        switch radius {
        case .medium:
            pinColor = Theme.accentColor1
        case .far:
            pinColor = Theme.accentColor2
        case .near:
            pinColor = Theme.accentColor3
        }
        annotationView?.pinTintColor = pinColor
        annotationView?.canShowCallout = true
        annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation as? VenueAnnotation,
            let venue = annotation.venue else {
                return
        }
        
        let viewController = VenueViewController(venue: venue)
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    // MARK: - Private
    
    // Radius options, expressed in meters.
    private enum Radius: Int, CaseIterable {
        case near = 200
        case medium = 500
        case far = 1000
    }
    
    private let mapView = MKMapView()
    private let venueManager = VenueManager()
    private var location: CLLocation? {
        didSet {
            resetMapRegion()
            updateVenues()
        }
    }
    private var radius: Radius = .medium {
        didSet {
            resetMapRegion()
            
            if radius != oldValue {
                updateRightBarButtonTitle()
                updateVenues()
            }
        }
    }
    
    private func configureMapView() {
        mapView.frame = view.bounds
        mapView.delegate = self
        mapView.showsUserLocation = true
        view.addSubview(mapView)
        
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     mapView.topAnchor.constraint(equalTo: view.topAnchor),
                                     mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                                     ])
    }
    
    private func configureNavigationItem() {
        let logo = UIImage(named: "Logo")?.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: logo)
        navigationItem.titleView = imageView
        
        let recenterIcon = UIImage(named: "RecenterIcon")?.withRenderingMode(.alwaysTemplate)
        let leftBarButtonItem = UIBarButtonItem(image: recenterIcon, style: .plain, target: self, action: #selector(resetMapRegion))
        navigationItem.leftBarButtonItem = leftBarButtonItem
        
        let rightBarButtonItem = UIBarButtonItem(title: nil, style: .plain, target: self, action: #selector(showRadiusPicker))
        navigationItem.rightBarButtonItem = rightBarButtonItem
        updateRightBarButtonTitle()
    }
    
    @objc private func resetMapRegion() {
        guard let location = location else {
            return
        }
        
        // The map resets to display the user in the center with the region fitting the currently selected radius.
        let diameter = CLLocationDistance(radius.rawValue) * 2
        var region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: diameter, longitudinalMeters: diameter)
        region = mapView.regionThatFits(region)
        mapView.setRegion(region, animated: true)
    }
    
    private func updateVenues() {
        guard let location = location else {
            return
        }

        mapView.removeAnnotations(mapView.annotations)

        let loadingIndicator = LoadingIndicator()
        loadingIndicator.show()
        venueManager.getVenues(forLocation: location, inRadius: radius.rawValue) { [weak self] result in
            DispatchQueue.main.async {
                loadingIndicator.hide()
                guard let strongSelf = self else {
                    return
                }
                
                switch result {
                case .success(let venues):
                    strongSelf.plot(venues: venues)
                case .failure(_):
                    AlertHandler.showNetworkErrorAlert(from: strongSelf)
                }
            }
        }
    }
    
    private func updateRightBarButtonTitle() {
        // Right bar button item displays the currently selected radius, expressed in minutes.
        navigationItem.rightBarButtonItem?.title = description(forRadius: radius, short: true)
    }
    
    private func plot(venues: [Venue]) {
        var annotations: [MKAnnotation] = []
        
        for venue in venues {
            let annotation = VenueAnnotation()
            annotation.coordinate = venue.location.coordinate
            annotation.title = venue.name
            annotation.subtitle = venue.address
            annotation.venue = venue
            
            annotations.append(annotation)
        }
        
        mapView.addAnnotations(annotations)
    }
    
    @objc private func showRadiusPicker() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let dismissAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(dismissAction)
        
        Radius.allCases.forEach { radius in
            let action = UIAlertAction(title: description(forRadius: radius, short: false), style: .default) { [weak self] _ in
                self?.radius = radius
            }
            alertController.addAction(action)
        }

        present(alertController, animated: true, completion: nil)
    }
    
    private func description(forRadius radius: Radius, short: Bool) -> String {
        let minutes = Utils.minutesToWalk(meters: radius.rawValue)
        return short ? "\(minutes) min" : "\(minutes) minute walk"
    }

}
