//
//  Utils.swift
//  CoffeeWalk
//
//  Created by Janina Kutyn on 2017-03-14.
//  Copyright © 2017 JaninaKutyn. All rights reserved.
//

import UIKit

struct Utils {

    static func minutesToWalk(meters: Int) -> Int {
        // I found average walking speed here: http://www.echocredits.org/downloads/2051055/With%2Bmy%2Bwalk.pdf
        // According to this source, the average walking speed is 1km per 10 min, which is 100m / min.
        return meters / 100
    }
}
