//
//  LoadingIndicator.swift
//  CoffeeWalk
//
//  Created by Janina Kutyn on 04/04/2019.
//  Copyright © 2019 JaninaKutyn. All rights reserved.
//

import UIKit

/// Displays a loading indicator in the center of keyWindow.
/// While indicator is shown, user interaction on keyWindow is disabled.
class LoadingIndicator {

    // MARK: - Public
    
    func show() {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
    
        toastView.addSubview(spinner)
        window.addSubview(toastView)
        
        toastView.translatesAutoresizingMaskIntoConstraints = false
        spinner.translatesAutoresizingMaskIntoConstraints = false
        
        // Let's make the toast 1/3 of the shortest side
        let shortestSideLength = min(window.bounds.height, window.bounds.width)
        let toastSideLength = shortestSideLength / 3
        
        NSLayoutConstraint.activate([toastView.centerXAnchor.constraint(equalTo: window.centerXAnchor),
                                     toastView.centerYAnchor.constraint(equalTo: window.centerYAnchor),
                                     toastView.widthAnchor.constraint(equalToConstant: toastSideLength),
                                     toastView.heightAnchor.constraint(equalToConstant: toastSideLength),
                                     
                                     spinner.centerXAnchor.constraint(equalTo: toastView.centerXAnchor),
                                     spinner.centerYAnchor.constraint(equalTo: toastView.centerYAnchor),
                                     ])
        
        toastView.superview?.isUserInteractionEnabled = false
        window.isUserInteractionEnabled = false
    }
    
    func hide() {
        toastView.superview?.isUserInteractionEnabled = true
        toastView.removeFromSuperview()
    }
    
    // MARK: - Private
    
    private lazy var toastView: UIView = {
        let view = UIView(frame: .zero)
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
        
        return view
    }()
    
    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .whiteLarge)
        spinner.startAnimating()
        return spinner
    }()
    
}
