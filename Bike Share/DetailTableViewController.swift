//
//  DetailTableViewController.swift
//  Bike Share
//
//  Created by Omar Abbasi on 2017-05-03.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import MapKit

extension UIButton {
    
    func setBackgroundColor(color: UIColor, forState: UIControlState) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.setBackgroundImage(colorImage, for: forState)
    }

}

class CustomPointAnnotation: MKPointAnnotation {
    
    var imageName: String!
    
}

class DetailTableViewController: UITableViewController, MKMapViewDelegate {

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var stationName: UILabel!
    @IBOutlet var availableBikes: UILabel!
    @IBOutlet var lastUpdated: UILabel!
    @IBOutlet var maxCapacity: UILabel!
    @IBOutlet var isReturning: UILabel!
    @IBOutlet var isRenting: UILabel!
    @IBOutlet var availableDocks: UILabel!
    @IBOutlet var disabledDocks: UILabel!
    @IBOutlet var disabledBikes: UILabel!
    @IBOutlet var getDirections: UIButton!
    @IBAction func unwindToMain(segue: UIStoryboardSegue) {}
    @IBAction func doneButton(_ sender: Any) {
        
        // dismiss(animated: true) { }
        
    }
    
    let defaults = UserDefaults.standard
    let tintColor = UIColor(red:0.06, green:0.81, blue:0.16, alpha:1.0)
    
    var station: BikeStation! {
        
        didSet {
            
            self.configureView()
            
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = tintColor
        
        mapView.delegate = self
        self.configureView()
        
        let gestureRecog = UILongPressGestureRecognizer(target: self, action: #selector(self.showMapsAppActionSheet))
        gestureRecog.minimumPressDuration = 0.4
        
        self.getDirections.addGestureRecognizer(gestureRecog)
        self.getDirections.addTarget(self, action: #selector(self.openMapsApp), for: .touchUpInside)
        self.getDirections.setBackgroundColor(color: UIColor(red:0.07, green:0.61, blue:0.93, alpha:1.0), forState: .normal)
        self.getDirections.setBackgroundColor(color: UIColor(red:0.06, green:0.41, blue:0.75, alpha:1.0), forState: .selected)
        
        let object = defaults.object(forKey: "defaultMapsApp") as! String
        print(object)
        
        self.getDirections.setImage(UIImage(named: object)?.withRenderingMode(.alwaysOriginal), for: .normal)
        
        self.centerMapOn(station.location)
        self.tableView.tableFooterView = UIView()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.estimatedRowHeight = 400
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.setNeedsLayout()
        self.tableView.layoutIfNeeded()
        self.tableView.reloadData()
    }

    func configureView() {
        
        if self.station != nil {
         
            if let label = self.stationName {
                label.text = station.address
            }
            
            if let label2 = self.lastUpdated {
                label2.text = "last updated on " + station.lastUpdated
            }
            
            if let label3 = self.maxCapacity {
                label3.text = "\(station.capacity)"
            }
            
            if let label4 = self.availableBikes {
                label4.text = "\(station.nbBikesAvailable)"
            }
            
            if let label5 = self.isReturning {
                label5.text = self.boolToString(station.isReturning)
            }
            
            if let label6 = self.isRenting {
                label6.text = self.boolToString(station.isRenting)
                
                let location = station.location.coordinate
                                
                let point = CustomPointAnnotation()
                point.imageName = "annotation"
                point.coordinate = location
                
                let pointView = MKPinAnnotationView(annotation: point, reuseIdentifier: "pin")
                
                self.mapView.addAnnotation(pointView.annotation!)
                
                DispatchQueue.main.async {
                    
                    self.tableView.reloadData()
                    
                }
                
            }
            
            if let label7 = self.availableDocks {
                label7.text = "\(station.nbDocksAvailable)"
            }
            
            if let label8 = self.disabledDocks {
                label8.text = "\(station.nbDisabledDocks)"
            }
            
            if let label9 = self.disabledBikes {
                label9.text = "\(station.nbDisabledBikes)"
            }
            
        }
        
    }
    
    func showMapsAppActionSheet() {
        
        let alertCtrl = UIAlertController(title: "Choose Default Maps App", message: "Which maps app would you like to use?", preferredStyle: .actionSheet)
        
        let defaultMapsApp = UIAlertAction(title: "Apple Maps", style: .default) { (action) in
            
            self.defaults.set("Apple Maps", forKey: "defaultMapsApp")
            self.getDirections.setImage(UIImage(named: self.defaults.object(forKey: "defaultMapsApp") as! String)?.withRenderingMode(.alwaysOriginal), for: .normal)
            
        }
        defaultMapsApp.setValue(UIImage(named: "Apple Maps")?.withRenderingMode(.alwaysOriginal), forKey: "image")
        
        let googleMaps = UIAlertAction(title: "Google Maps", style: .default) { (action) in
            
            self.defaults.set("Google Maps", forKey: "defaultMapsApp")
            self.getDirections.setImage(UIImage(named: self.defaults.object(forKey: "defaultMapsApp") as! String)?.withRenderingMode(.alwaysOriginal), for: .normal)
            
        }
        googleMaps.setValue(UIImage(named: "Google Maps")?.withRenderingMode(.alwaysOriginal), forKey: "image")
        
        let waze = UIAlertAction(title: "Waze", style: .default) { (action) in
            
            self.defaults.set("Waze", forKey: "defaultMapsApp")
            self.getDirections.setImage(UIImage(named: self.defaults.object(forKey: "defaultMapsApp") as! String)?.withRenderingMode(.alwaysOriginal), for: .normal)
            
        }
        waze.setValue(UIImage(named: "Waze")?.withRenderingMode(.alwaysOriginal), forKey: "image")
        
        if let appName = defaults.object(forKey: "defaultMapsApp") as? String {
            
            if appName == "Apple Maps" {
                
                defaultMapsApp.setValue(true, forKey: "checked")
                
            } else if appName == "Google Maps" {
                
                googleMaps.setValue(true, forKey: "checked")
                
            } else {
                
                waze.setValue(true, forKey: "checked")
                
            }
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertCtrl.view.tintColor = UIColor.black
        alertCtrl.addAction(defaultMapsApp)
        alertCtrl.addAction(googleMaps)
        alertCtrl.addAction(waze)
        alertCtrl.addAction(cancelAction)
        self.present(alertCtrl, animated: true, completion: nil)
        
    }
    
    func openMapsApp() {
        
        let lat = String(station.location.coordinate.latitude)
        let long = String(station.location.coordinate.longitude)
        
        if defaults.object(forKey: "defaultMapsApp") == nil {
            
            if let url = URL(string: "http://maps.apple.com/?ll=" + lat + "," + long) {
                
                UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                    
                    if !success {
                        
                        let alert = UIAlertController(title: "Failed To Open Maps", message: "There's been a slight complication. Make sure you have Maps installed on your iPhone.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        
                    }
                    
                })
            }
            
        } else if let appName = defaults.object(forKey: "defaultMapsApp") as? String {
            
            if appName == "Apple Maps" {
                
                if let url = URL(string: "http://maps.apple.com/?ll=" + lat + "," + long) {
                    
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                        
                        if !success {
                            
                            let alert = UIAlertController(title: "Failed To Open Maps", message: "There's been a slight complication. Make sure you have Maps installed on your iPhone.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            
                        }
                        
                    })
                } else {
                    
                    print("oh no....")
                    
                }
                
            } else if appName == "Google Maps" {
                
                if let url = URL(string: "comgooglemaps://?center=" + lat + "," + long) {
                    
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                        
                        if !success {
                            
                            let alert = UIAlertController(title: "Failed To Open Google Maps", message: "There's been a slight complication. Make sure you have Google Maps installed on your iPhone.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            
                        }
                        
                    })
                }
                
            } else {
                
                // waze
                if let url = URL(string: "waze://?ll=" + lat + "," + long) {
                    
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                        
                        if !success {
                            
                            let alert = UIAlertController(title: "Failed To Open Waze", message: "There's been a slight complication. Make sure you have Waze installed on your iPhone.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            
                        }
                        
                    })
                }
                
            }
            
        }
        
    }
    
    func centerMapOn(_ location: CLLocation) {
        
        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 250, 250)
        mapView.setRegion(region, animated: true)
        
    }
    
    func boolToString(_ bool: Bool) -> String {
        
        if bool {
            return "✓"
        } else {
            return "𐄂"
        }
        
    }
    
    // MARK: - Map view delegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseIdentifier = "pin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        if annotationView == nil {
            
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView?.canShowCallout = false
            
        } else {
            
            annotationView?.annotation = annotation
            
        }
        
        annotationView?.image = UIImage(named: "annotation")
        
        return annotationView
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
