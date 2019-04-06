//
//  VenueManager.swift
//  NearbyCoffee
//
//  Created by Janina Kutyn on 2017-03-10.
//  Copyright © 2017 JaninaKutyn. All rights reserved.
//

import CoreLocation

/// This class accesses FourSquare's API to retrieve recommended coffee shop venues and their details
final class VenueManager {
    
    // MARK: - Public
    
    /**
     Retrieves recommended coffee shops within the specified radius.
     If a previous request is still in progress, it will be cancelled, and the caller will receive a callback with Result type .canceled()
     before receiving the callback for the most current request.
     - parameters:
     - location: location around which to query
     - radius: distance how far to query in meters
     - completion: block that handles completion of the call
     */
    func getVenues(forLocation location: CLLocation, inRadius radius: Int, completion: @escaping (Result<[Venue]>) -> Void) {
        task?.cancel()
        
        guard let url = url(forLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, radius: radius) else {
            let unsupportedUrlError = NSError(domain: "", code: NSURLErrorUnsupportedURL, userInfo: nil)
            completion(.failure(unsupportedUrlError))
            return
        }
        
        task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            // We may have a situation where we receive both an error and valid data.
            // I chose to handle one or the other, as data accompanied by an error may be compromised.
            if let error = error as NSError? {
                if error.code == NSURLErrorCancelled {
                    completion(.canceled)
                } else {
                    completion(.failure(error))
                }
            } else {
                guard let json = NetworkingUtils.json(fromData: data),
                    let venueDescriptions = self?.venueDescriptions(fromJson: json) else {
                        let parsingError = NSError(domain: "", code: NSURLErrorCannotParseResponse, userInfo: nil)
                        completion(.failure(parsingError))
                        return
                }
                
                var venues: [Venue] = []
                
                for itemDescription in venueDescriptions {
                    if let venue = self?.venue(from: itemDescription) {
                        venues.append(venue)
                    }
                }
                
                completion(.success(venues))
            }
        }
        
        task?.resume()
    }
    
    /**
     Retrieves the details of a specified venue
     If a previous request is still in progress, it will be cancelled, and the caller will receive a callback with Result type .canceled()
     before receiving the callback for the most current request.
     - parameters:
     - location: location around which to query
     - radius: distance how far to query in meters
     - completion: block that handles completion of the call
     */
    func getVenueDetails(for venue: Venue, completion: @escaping (Result<Venue>) -> Void) {
        task?.cancel()
        
        guard let url = url(forVenue: venue) else {
            let unsupportedUrlError = NSError(domain: "", code: NSURLErrorUnsupportedURL, userInfo: nil)
            completion(.failure(unsupportedUrlError))
            return
        }
        
        task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error as NSError? {
                if error.code == NSURLErrorCancelled {
                    completion(.canceled)
                } else {
                    completion(.failure(error))
                }
            } else {
                guard let json = NetworkingUtils.json(fromData: data),
                    let venueDetails = self?.venueDetails(fromJson: json) else {
                        let parsingError = NSError(domain: "", code: NSURLErrorCannotParseResponse, userInfo: nil)
                        completion(.failure(parsingError))
                        return
                }
                
                var updatedVenue = venue
                updatedVenue.websiteURL = venueDetails["url"] as? String
                if let contactDetails = venueDetails["contact"] as? [String: Any] {
                    updatedVenue.phoneNumber = contactDetails["formattedPhone"] as? String
                    updatedVenue.dialablePhoneNumber = contactDetails["phone"] as? String
                }
                
                completion(.success(updatedVenue))
            }
        }
        
        task?.resume()
    }
    
    // MARK: - Private
    
    private var task: URLSessionDataTask?
    
    private let baseURLString = "https://api.foursquare.com/v2/venues"
    
    // clientID and clientSecret were generated in FourSquare's developer portal.
    private let clientID = "ATF2CH5CJIV4JX4QAONLPJP4FDQN5HWQSG3B2M0NZDIQLUPA"
    private let clientSecret = "DVBSFSMCJ2K4JZMSSHNVILQBKXUOLQSNF0CBOLS4RDF4VRVI"
    
    private func url(forVenue venue: Venue) -> URL? {
        var urlString = "\(baseURLString)/\(venue.venueID)?"
        urlString = urlStringWithCredentials(urlString)
        return URL(string: urlString)
    }
    
    private func url(forLatitude latitude: Double, longitude: Double, radius: Int) -> URL? {
        var urlString = "\(baseURLString)/explore?ll=\(latitude),\(longitude)&radius=\(radius)&section=coffee&"
        urlString = urlStringWithCredentials(urlString)
        return URL(string: urlString)
    }
    
    private func urlStringWithCredentials(_ string: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: Date())
        
        let urlString = "\(string)client_id=\(clientID)&client_secret=\(clientSecret)&v=\(dateString)"
        return urlString
    }
    
    private func venueDescriptions(fromJson json: [String: Any]) -> [[String: Any]]? {
        guard let response = json["response"] as? [String: Any],
            let groups = response["groups"] as? [Any],
            // The first group is Recommended venues
            let group = groups.first as? [String: Any] else {
                return nil
        }
        
        return group["items"] as? [[String: Any]]
    }
    
    private func venueDetails(fromJson json: [String: Any]) -> [String: Any]? {
        guard let response = json["response"] as? [String: Any] else {
            return nil
        }
        return response["venue"] as? [String: Any]
    }
    
    private func venue(from itemDescription: [String: Any]) -> Venue? {
        guard let venueDescription = itemDescription["venue"] as? [String: Any],
            let venueID = venueDescription["id"] as? String,
            let name = venueDescription["name"] as? String,
            let locationDescription = venueDescription["location"] as? [String: Any],
            let latLongArray = locationDescription["labeledLatLngs"] as? [Any],
            // latitude and longitude dictionary is item 0 in latLongArray
            let latLongDescription = latLongArray.first as? [String: Any],
            let latitude = latLongDescription["lat"] as? Double,
            let longitude = latLongDescription["lng"] as? Double
            else {
                // Don't bother creating this venue if it doesn't contain values
                // necessary to populate the non-optional properties of a Venue.
                return nil
        }
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let address  = locationDescription["address"] as? String
        
        let venue = Venue(venueID: venueID, name: name, location: location, address: address, websiteURL: nil, phoneNumber: nil, dialablePhoneNumber: nil)
        return venue
    }

}
