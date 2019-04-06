//
//  Venue.swift
//  NearbyCoffee
//
//  Created by Janina Kutyn on 2017-03-10.
//  Copyright © 2017 JaninaKutyn. All rights reserved.
//

import UIKit
import CoreLocation

struct Venue {
    
    var venueID: String
    var name: String
    var location: CLLocation
    var address: String?
    var websiteURL: String?
    var phoneNumber: String?
    var dialablePhoneNumber: String?
}
