//
//  Result.swift
//  CoffeeWalk
//
//  Created by Janina Kutyn on 06/04/2019.
//  Copyright © 2019 JaninaKutyn. All rights reserved.
//

import Foundation

enum Result<Value> {
    case success(Value)
    case failure(Error)
    case canceled
}
