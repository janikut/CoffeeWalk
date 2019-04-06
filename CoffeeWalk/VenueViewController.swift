//
//  VenueViewController.swift
//  CoffeeWalk
//
//  Created by Janina Kutyn on 04/04/2019.
//  Copyright © 2019 JaninaKutyn. All rights reserved.
//

import UIKit
import SafariServices

final class VenueViewController: UITableViewController {
    
    // MARK: - Object Lifecycle
    
    init(venue: Venue) {
        self.venue = venue
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        
        // To prevent extra separators shown below the cells we are using
        tableView.tableFooterView = UIView()

        configureForCurrentVenue()
        updateVenueDetails()
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return VenueDetail.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "ReuseIdentifier"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if (cell == nil) {
            cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: cellIdentifier)
        }
        
        if let venueDetail = VenueDetail(rawValue: indexPath.row) {
            switch venueDetail {
            case .address:
                cell!.textLabel?.text = "Address"
                cell!.detailTextLabel?.text = venue.address ?? "Address unavailable"
            case .website:
                cell!.textLabel?.text = "Website"
                cell!.detailTextLabel?.text = venue.websiteURL ?? "Website unavailable"
            case .phoneNumber:
                cell!.textLabel?.text = "Phone number"
                cell!.detailTextLabel?.text = venue.phoneNumber ?? "Phone number unavailable"
            }
        }

        return cell!
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let venueDetail = VenueDetail(rawValue: indexPath.row) else {
            return
        }
        
        switch venueDetail {
        case .website:
            openVenuWebsite()
        case .phoneNumber:
            callVenue()
        default:
            break
        }
    }
    
    // MARK: - Private
    
    private enum VenueDetail: Int, CaseIterable {
        case address
        case website
        case phoneNumber
    }
    
    private var venue: Venue {
        didSet {
            configureForCurrentVenue()
            tableView.reloadData()
        }
    }
    private var venueManager = VenueManager()
    
    private func configureForCurrentVenue() {
        title = venue.name
    }
    
    private func updateVenueDetails() {
        let loadingIndicator = LoadingIndicator()
        loadingIndicator.show()
        venueManager.getVenueDetails(for: venue) { [weak self] result in
            DispatchQueue.main.async {
                loadingIndicator.hide()
                guard let strongSelf = self else {
                    return
                }
                
                switch result {
                case .success(let venue):
                    strongSelf.venue = venue
                case .failure(_):
                    AlertHandler.showNetworkErrorAlert(from: strongSelf)
                case .canceled:
                    break
                }
            }
        }
    }
    
    private func callVenue() {
        guard let phoneNumber = venue.dialablePhoneNumber,
            let phoneURL = URL(string: "tel://\(phoneNumber)") else {
                return
        }
        
        UIApplication.shared.open(phoneURL)
    }
    
    private func openVenuWebsite() {
        guard let website = venue.websiteURL,
            let webURL = URL(string: website) else {
                return
        }
        
        let webViewController = SFSafariViewController(url: webURL)
        present(webViewController, animated: true)
    }

}
