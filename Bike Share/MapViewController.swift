//
//  ViewController.swift
//  Bike Share
//
//  Created by Omar Abbasi on 2017-05-02.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import SwiftyJSON
import Alamofire
import LNPopupController

class StationAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var name: String!
    var bikesAvail: String!
    var stationToUse: BikeStation!
    var image: UIImage!
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate, LNPopupBarPreviewingDelegate, SelectedBikeStationDelegate {
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var actvityVisualView: UIVisualEffectView!
    @IBAction func unwindToMenu(segue: UIStoryboardSegue) {}
    
    private var popUpContentVC: MainTableViewController!
    
    var bikeStations = [BikeStation]()
    var currentLocation = CLLocation()
    var annotationsInView = [Any]()
    
    let defaults = UserDefaults.standard
    
    var customPopUpBar = PopViewController()
    var popupContentController = MainTableViewController()
    
    let tintColor = UIColor(red:0.06, green:0.81, blue:0.16, alpha:1.0)
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if defaults.object(forKey: "defaultMapsApp") as? String == nil {
            
            defaults.set("Apple Maps", forKey: "defaultMapsApp")
            
        }
        
        self.navigationController?.navigationBar.tintColor = tintColor
        
        let statusBarView = UIView(frame: CGRect(x:0, y:0, width:view.frame.size.width, height: UIApplication.shared.statusBarFrame.height))
        let blurEffect = UIBlurEffect(style: .extraLight) // Set any style you want(.light or .dark) to achieve different effect.
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = statusBarView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        statusBarView.addSubview(blurEffectView)
        view.addSubview(statusBarView)
        
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
        self.actvityVisualView.isHidden = false
        
        currentLocation = CLLocation(latitude: 43.6628917, longitude: -79.39565640000001)
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        self.centerMapOn(self.currentLocation)
        
        loadStations { (success) in
            self.makeStations()
            
            let targetVC = self
            
            self.customPopUpBar = self.storyboard?.instantiateViewController(withIdentifier: "PopViewController") as! PopViewController
            self.customPopUpBar.view.backgroundColor = UIColor.clear
            
            self.popupBar.customBarViewController = self.customPopUpBar
            
            self.popupContentController = self.storyboard?.instantiateViewController(withIdentifier: "MainTableViewController") as! MainTableViewController
            self.popupContentController.tableView.backgroundColor = UIColor.clear
            self.popupContentController.tableView.backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
            self.popupContentController.delegate = self
            self.popupContentController.popupItem.title = "\(self.bikeStations.count)"
            
            targetVC.popupBar.previewingDelegate = self
            targetVC.popupBar.backgroundStyle = UIBlurEffectStyle.extraLight
            targetVC.popupInteractionStyle = .drag
            targetVC.popupContentView.popupCloseButtonStyle = .none
            targetVC.presentPopupBar(withContentViewController: self.popupContentController, animated: true, completion: nil)
            
            let annotations = self.mapView.annotations(in: self.mapView.visibleMapRect)
            self.annotationsInView = Array(annotations)
            self.popupContentController.popupItem.title = "\(self.annotationsInView.count)"
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadStations(completionHandler: @escaping (Bool) -> ()) {
        
        loadStationInformation { (success) in
            
            self.loadStationStatus(completionHandler: { (success) in
                
                completionHandler(true)
                
            })
            
        }
        
    }
    
    func loadStationInformation(completionHandler: @escaping (Bool) -> ()) {
        
        Alamofire.request("https://tor.publicbikesystem.net/ube/gbfs/v1/en/station_information").responseJSON { (Response) in
            
            if let value = Response.result.value {
                
                let json = JSON(value)
                
                // let lastDataUpdate = json["last_updated"].doubleValue
                // let lastUpdate = Date(timeIntervalSince1970: lastDataUpdate)
                
                for station in json["data"]["stations"].arrayValue {
                    
                    let id = station["station_id"].intValue
                    let name = station["name"].stringValue
                    let location = CLLocation(latitude: station["lat"].doubleValue, longitude: station["lon"].doubleValue)
                    let distance = location.distance(from: self.currentLocation)
                    let address = station["address"].stringValue
                    let capacity = station["capacity"].intValue
                    
                    let newStation = BikeStation(id: id, name: name, location: location, distance: distance, address: address, capacity: capacity)
                    self.bikeStations.append(newStation)
                    
                }
                
                completionHandler(true)
            }
            
        }
        
    }
    
    func loadStationStatus(completionHandler: @escaping (Bool) -> ()) {
        
        Alamofire.request("https://tor.publicbikesystem.net/ube/gbfs/v1/en/station_status").responseJSON { (Response) in
            
            if let value = Response.result.value {
                
                let json = JSON(value)
                
                let stationsArr = json["data"]["stations"].arrayValue
                
                var stationsIndex = 0
                for bikeStation in self.bikeStations {
                    
                    let station = stationsArr[stationsIndex]
                    
                    let epoch = (station["last_reported"].doubleValue) / 1000
                    // divide by 1000 because ¯\_(ツ)_/¯
                    
                    let lastDate = Date(timeIntervalSince1970: epoch)
                    let dateFormatter = DateFormatter()
                    dateFormatter.timeZone = TimeZone.current
                    dateFormatter.locale = Locale.current
                    dateFormatter.dateFormat = "MMM dd, hh:mm a"
                    
                    let nbBikesAvailable = station["num_bikes_available"].intValue
                    let nbDisabledBikes = station["num_bikes_disabled"].intValue
                    let nbDocksAvailable = station["num_docks_available"].intValue
                    let nbDisabledDocks = station["num_docks_disabled"].intValue
                    let isInstalled = station["is_installed"].boolValue
                    let isRenting = station["is_renting"].boolValue
                    let isReturning = station["is_returning"].boolValue
                    let lastUpdated = dateFormatter.string(from: lastDate)
                    
                    bikeStation.nbBikesAvailable = nbBikesAvailable
                    bikeStation.nbDisabledBikes = nbDisabledBikes
                    bikeStation.nbDocksAvailable = nbDocksAvailable
                    bikeStation.nbDisabledDocks = nbDisabledDocks
                    bikeStation.isInstalled = isInstalled
                    bikeStation.isRenting = isRenting
                    bikeStation.isReturning = isReturning
                    bikeStation.lastUpdated = lastUpdated
                    
                    stationsIndex += 1
                    
                }
                
                completionHandler(true)
                
            }
            
        }
        
    }
    
    func makeStations() {
                
        self.bikeStations.sort(by: { $0.distance < $1.distance })
        
        for station in bikeStations {
            
            let location = station.location.coordinate
            let point = StationAnnotation(coordinate: location)
            point.image = UIImage(named: "annotation")
            point.name = station.name
            point.bikesAvail = "\(station.nbBikesAvailable) available"
            point.stationToUse = station
            self.mapView.addAnnotation(point)
            
        }
        
        self.activityIndicator.stopAnimating()
        self.actvityVisualView.isHidden = true
        
    }
    
    func centerMapOn(_ location: CLLocation) {
        
        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
        mapView.setRegion(region, animated: true)
        
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if view.annotation is MKUserLocation {
            // Don't proceed with custom callout
            return
            
        }
        
        let stationAnnotation = view.annotation as! StationAnnotation
        let views = Bundle.main.loadNibNamed("CalloutView", owner: nil, options: nil)
        let calloutView = views?[0] as! CalloutView
        calloutView.station = stationAnnotation.stationToUse
        
        let button = UIButton(frame: calloutView.bounds)
        button.addTarget(self, action: #selector(self.goToDetailView), for: .touchUpInside)
        
        calloutView.center = CGPoint(x: view.bounds.size.width / 2, y: -calloutView.bounds.size.height * 0.52)
        calloutView.addSubview(button)
        
        calloutView.alpha = 0.0
                
        UIView.animate(withDuration: 0.3) {
            
            calloutView.alpha = 1.0
            view.addSubview(calloutView)
            
        }
        
        mapView.setCenter((view.annotation?.coordinate)!, animated: true)
        
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        
        self.popupContentController.popupItem.title = "\(self.annotationsInView.count)"
        self.popupContentController.popupItem.subtitle = ""
        
        if view.isKind(of: AnnotationView.self) {
            
            for subview in view.subviews {
                
                UIView.animate(withDuration: 0.2) {
                    
                    subview.alpha = 0.0
                    subview.removeFromSuperview()
                    
                }
                
            }
            
        }
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseIdentifier = "pin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        if annotationView == nil {
            
            annotationView = AnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView?.canShowCallout = false
            
        } else {
            
            annotationView?.annotation = annotation
            
        }
        
        annotationView?.image = UIImage(named: "annotation")
        
        return annotationView
        
    }
    
    func previewingViewController(for popupBar: LNPopupBar) -> UIViewController? {
        
        let vc = UIViewController()
        vc.view.backgroundColor = UIColor.white
        
        let label = UILabel(frame: vc.view.bounds)
        label.text = "Oh Boy I Wasn't Prepared For This"
        label.font = UIFont.systemFont(ofSize: 30, weight: UIFontWeightThin)
        label.textAlignment = .center
        label.numberOfLines = 0
        
        vc.view.addSubview(label)
        
        return vc
        
    }
    
    func selected(_ bikeStation: BikeStation) {
        
        for ann in self.mapView.annotations {
            
            if let annBikeStation = ann as? StationAnnotation {
                
                if annBikeStation.stationToUse.id == bikeStation.id {
                    
                    self.mapView.selectAnnotation(ann, animated: true)
                    
                }
                
            }
            
        }
        
        
    }
    
    private var mapChangedFromUserInteraction = false
    
    private func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        let view = self.mapView.subviews[0]
        if let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if (recognizer.state == UIGestureRecognizerState.began || recognizer.state == UIGestureRecognizerState.ended) {
                    return true
                }
            }
        }
        return false
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        mapChangedFromUserInteraction = mapViewRegionDidChangeFromUserInteraction()
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        if mapView.selectedAnnotations.count == 0 {
            
            if (mapChangedFromUserInteraction) {
                
                let annotations = self.mapView.annotations(in: self.mapView.visibleMapRect)
                self.annotationsInView = Array(annotations)
                self.popupContentController.popupItem.title = "\(self.annotationsInView.count)"
                
            }
            
        }
        
    }
    
    
    func goToDetailView() {
        
        if let ann = self.mapView.selectedAnnotations[0] as? StationAnnotation {
            
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "DetailTableViewController") as? DetailTableViewController {
                vc.station = ann.stationToUse
                
                vc.tableView.backgroundColor = UIColor.clear
                vc.tableView.backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.light))
                
                let gps = UINavigationController(rootViewController: vc)
                gps.modalPresentationStyle = .overFullScreen
                self.present(gps, animated: true, completion: nil)
                
            }
            
        }
        
        // performSegue(withIdentifier: "showDetailFromMap", sender: self)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showDetailFromMap" {
            
            if let ann = self.mapView.selectedAnnotations[0] as? StationAnnotation {
                
                let destVC = (segue.destination as! UINavigationController).topViewController as? DetailTableViewController
                destVC?.station = ann.stationToUse
                
            }
            
        }
        
    }
    
}

