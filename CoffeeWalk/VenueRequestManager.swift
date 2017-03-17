//
//  VenueRequestManager.swift
//  NearbyCoffee
//
//  Created by Janina Kutyn on 2017-03-10.
//  Copyright © 2017 JaninaKutyn. All rights reserved.
//

import CoreLocation

enum Result<Value> {
    case success(Value)
    case failure(Error)
    case canceled()
}

class VenueRequestManager {
    
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
            print("\(#file), \(#function): Invalid URL.")
            let unsupportedUrlError = NSError(domain: "", code: NSURLErrorUnsupportedURL, userInfo: nil)
            completion(.failure(unsupportedUrlError))
            return
        }
        
        task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            // We may have a situation where we receive both an error and valid data.
            // I chose to handle one or the other, as data accompanied by an error may be compromised.
            if let error = error as? NSError {
                if error.code == NSURLErrorCancelled {
                    completion(.canceled())
                } else {
                    completion(.failure(error))
                }
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
    
    // MARK: - Private
    
    private var task: URLSessionDataTask?
    
    private let baseURLString = "https://api.foursquare.com/v2/venues/explore"
    // clientID and clientSecret were generated in FourSquare's developer portal.
    private let clientID = "ATF2CH5CJIV4JX4QAONLPJP4FDQN5HWQSG3B2M0NZDIQLUPA"
    private let clientSecret = "DVBSFSMCJ2K4JZMSSHNVILQBKXUOLQSNF0CBOLS4RDF4VRVI"
    private var dateString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        return dateFormatter.string(from: Date())
    }
    
    private func url(forLatitude latitude: Double, longitude: Double, radius: Int) -> URL? {
        // Since I'm only making this one web call, this was the simplest way to construct the url string.
        // If we had to make many different calls, a utility method to create parameters from dictionary would be more useful.
        let urlString = "\(baseURLString)?ll=\(latitude),\(longitude)&radius=\(radius)&section=coffee&client_id=\(clientID)&client_secret=\(clientSecret)&v=\(dateString)"
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
            groups.count > 0, // Group 0 is Recommended venues
            let group = groups[0] as? [String: Any],
            let items = group["items"] as? [[String: Any]] else {
                return nil
        }
        
        return items
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
        let website = venueJson["url"] as? String
        let address  = locationDescription["address"] as? String
        
        let venue = Venue(venueID: venueID, name: name, location: location, website: website, address: address)
        return venue
    }
    
}
