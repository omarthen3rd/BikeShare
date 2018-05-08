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
    @IBOutlet var distanceAway: UILabel!
    @IBOutlet var lastUpdated: UILabel!
    @IBOutlet var stationAvailableDocks: UILabel!
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
            
            var distance = String()
            
            let distanceMeters = Measurement(value: station.distance, unit: UnitLength.meters)
            let distanceKilometers = distanceMeters.converted(to: UnitLength.kilometers)
            
            if distanceKilometers.value < 1.0 {
                
                let numberFormatter = NumberFormatter()
                numberFormatter.maximumFractionDigits = 2
                let measurementFormatter = MeasurementFormatter()
                measurementFormatter.unitOptions = .providedUnit
                measurementFormatter.numberFormatter = numberFormatter
                distance = "0" + measurementFormatter.string(from: distanceKilometers)
                
            } else {
                
                let numberFormatter = NumberFormatter()
                numberFormatter.maximumFractionDigits = 1
                let measurementFormatter = MeasurementFormatter()
                measurementFormatter.unitOptions = .providedUnit
                measurementFormatter.numberFormatter = numberFormatter
                distance = measurementFormatter.string(from: distanceKilometers)
                
            }
            
            stationName.text = station.address
            distanceAway.text = "\(distance) away"
            lastUpdated.text = "updated \(station.lastUpdated)"
            stationBikesAvailable.text = "\(station.nbBikesAvailable)"
            stationAvailableDocks.text = "\(station.nbDocksAvailable)"
            isReturning.text = boolToString(station.isReturning)
            isRenting.text = boolToString(station.isRenting)
            
        }
        
    }
    
    func boolToString(_ bool: Bool) -> String {
        
        // if bool ? if true : else
        return bool ? "✓" : "𐄂"
    }
    
}
