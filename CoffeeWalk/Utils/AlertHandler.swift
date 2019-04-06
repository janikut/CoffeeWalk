//
//  AlertHandler.swift
//  CoffeeWalk
//
//  Created by Janina Kutyn on 06/04/2019.
//  Copyright © 2019 JaninaKutyn. All rights reserved.
//

import UIKit

struct AlertHandler {

    static func showNetworkErrorAlert(from viewController: UIViewController) {
        // Generic message for network errors.
        let alertController = UIAlertController(title: "Oops", message: "Something went wrong.", preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(dismissAction)
        viewController.present(alertController, animated: true, completion: nil)
    }
}
