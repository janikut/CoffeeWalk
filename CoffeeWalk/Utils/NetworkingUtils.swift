//
//  NetworkingUtils.swift
//  CoffeeWalk
//
//  Created by Janina Kutyn on 06/04/2019.
//  Copyright © 2019 JaninaKutyn. All rights reserved.
//

import Foundation

struct NetworkingUtils {
    
    static func json(fromData data: Data?) -> [String: Any]? {
        guard let data = data else {
            return nil
        }
        
        let json: [String: Any]?
        do {
            json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        } catch _ {
            json = nil
        }
        return json
    }
    
}
