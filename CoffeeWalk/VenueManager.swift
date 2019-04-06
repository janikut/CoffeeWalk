//
//  VenueManager.swift
//  NearbyCoffee
//
//  Created by Janina Kutyn on 2017-03-10.
//  Copyright © 2017 JaninaKutyn. All rights reserved.
//

import CoreLocation

enum Result<Value> {
    case success(Value)
    case failure(Error)
}

class VenueManager {
    
    // MARK: - Public
    
    /**
     This method accesses FourSquare's API and retrieves recommended coffee shops (not the Amsterdam kind!) within the specified radius.
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
                completion(.failure(error))
            } else {
                guard
                    let data = data,
                    let json = self?.json(fromData: data),
                    let venueJsonDescriptions = self?.venueJsonDescriptions(fromJson: json) else {
                        let parsingError = NSError(domain: "", code: NSURLErrorCannotParseResponse, userInfo: nil)
                        completion(.failure(parsingError))
                        return
                }
                
                var venues: [Venue] = []
                
                for itemJson in venueJsonDescriptions {
                    if let venue = self?.venue(fromJson: itemJson) {
                        venues.append(venue)
                    }
                }
                
                completion(.success(venues))
            }
        }
        
        task?.resume()
    }
    
    func getVenueDetails(for venue: Venue, completion: @escaping (Result<Venue>) -> Void) {
        task?.cancel()
        
        guard let url = url(forVenue: venue) else{
            let unsupportedUrlError = NSError(domain: "", code: NSURLErrorUnsupportedURL, userInfo: nil)
            completion(.failure(unsupportedUrlError))
            return
        }
        
        task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error as NSError? {
                completion(.failure(error))
            } else {
                guard
                    let data = data,
                    let json = self?.json(fromData: data),
                    let venueDetails = self?.venueDetailsJsonDescriptions(fromJson: json) else {
                        let parsingError = NSError(domain: "", code: NSURLErrorCannotParseResponse, userInfo: nil)
                        completion(.failure(parsingError))
                        return
                }
                
                var updatedVenue = venue
                updatedVenue.websiteURL = venueDetails["url"] as? String
                if let contactDescription = venueDetails["contact"] as? [String: Any] {
                    updatedVenue.phoneNumber = contactDescription["formattedPhone"] as? String
                    updatedVenue.dialablePhoneNumber = contactDescription["phone"] as? String 
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
    private var dateString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        return dateFormatter.string(from: Date())
    }
    
    private func url(forVenue venue: Venue) -> URL? {
        let urlString = "\(baseURLString)/\(venue.venueID)?client_id=\(clientID)&client_secret=\(clientSecret)&v=\(dateString)"
        return URL(string: urlString)
    }
    
    private func url(forLatitude latitude: Double, longitude: Double, radius: Int) -> URL? {
        let urlString = "\(baseURLString)/explore?ll=\(latitude),\(longitude)&radius=\(radius)&section=coffee&client_id=\(clientID)&client_secret=\(clientSecret)&v=\(dateString)"
        return URL(string: urlString)
    }

    private func json(fromData data: Data) -> [String: Any]? {
        let json: [String: Any]?
        do {
            json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        } catch _ {
            json = nil
        }
        return json
    }
    
    private func venueJsonDescriptions(fromJson json: [String: Any]) -> [[String: Any]]? {
        guard
            let response = json["response"] as? [String: Any],
            let groups = response["groups"] as? [Any],
            // The first group is Recommended venues
            let group = groups.first as? [String: Any] else {
                return nil
        }
        
        return group["items"] as? [[String: Any]]
    }
    
    private func venueDetailsJsonDescriptions(fromJson json: [String: Any]) -> [String: Any]? {
        guard
            let response = json["response"] as? [String: Any] else {
                return nil
        }
        return response["venue"] as? [String: Any]
    }
    
    private func venue(fromJson itemJson: [String: Any]) -> Venue? {
        // This function could also be moved to a JSON manager type object that deals with parsing data into known types.
        guard
            let venueJson = itemJson["venue"] as? [String: Any],
            let venueID = venueJson["id"] as? String,
            let name = venueJson["name"] as? String,
            let locationDescription = venueJson["location"] as? [String: Any],
            let latLongArray = locationDescription["labeledLatLngs"] as? [Any],
            latLongArray.count > 0, // latitude and longitude dictionary is item 0 in latLongArray
            let latLongDescription = latLongArray[0] as? [String: Any],
            let latitude = latLongDescription["lat"] as? Double,
            let longitude = latLongDescription["lng"] as? Double
            else {
                // Don't bother creating this venue if it doesn't contain values
                // necessary to populate the non-optional properties of a Venue.
                return nil
        }
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let address  = locationDescription["address"] as? String
        
        let venue = Venue(venueID: venueID, name: name, location: location, websiteURL: nil, address: address, phoneNumber: nil, dialablePhoneNumber: nil)
        return venue
    }
    
}
