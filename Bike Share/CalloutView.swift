//
//  CalloutView.swift
//  Bike Share
//
//  Created by Omar Abbasi on 2017-05-03.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit

class CalloutView: UIView {
    
    @IBOutlet var mainView: UIView!
    @IBOutlet var stationBikesAvailable: UILabel!
    @IBOutlet var stationName: UILabel!
    @IBOutlet var lastUpdated: UILabel!
    @IBOutlet var stationMaxCapacity: UILabel!
    @IBOutlet var isReturning: UILabel!
    @IBOutlet var isRenting: UILabel!
    
    var station: BikeStation! {
        
        didSet {
            
            mainView.layer.cornerRadius = 15
            mainView.backgroundColor = UIColor.white
            mainView.layer.shadowColor = UIColor.black.cgColor
            mainView.layer.shadowOffset = CGSize(width: 0, height: 5)
            mainView.layer.shadowRadius = 5
            mainView.layer.shadowOpacity = 0.2
            mainView.layer.shadowPath = UIBezierPath(roundedRect: mainView.bounds, cornerRadius: 15).cgPath
            
            stationBikesAvailable.text = "\(station.nbBikesAvailable)"
            stationName.text = station.address
            lastUpdated.text = "last updated \(station.lastUpdated)"
            stationMaxCapacity.text = "\(station.capacity)"
            isReturning.text = boolToString(station.isReturning)
            isRenting.text = boolToString(station.isRenting)
            
        }
        
    }
    
    func boolToString(_ bool: Bool) -> String {
        
        if bool {
            
            return "✓"
            
        } else {
            
            return "𐄂"
            
        }
        
    }
    
}
