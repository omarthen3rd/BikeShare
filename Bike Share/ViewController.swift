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
    
    private var popUpContentVC: MainTableViewController!
    
    var bikeStations = [BikeStation]()
    var currentLocation = CLLocation()
    var annotationsInView = [Any]()
    
    var popupContentController = MainTableViewController()
    
    let tintColor = UIColor(red:0.06, green:0.81, blue:0.16, alpha:1.0)
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("ran this")
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
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
            
            self.popupContentController = self.storyboard?.instantiateViewController(withIdentifier: "MainTableViewController") as! MainTableViewController
            
            self.popupContentController.bikeStations = self.bikeStations
            self.popupContentController.tableView.backgroundColor = UIColor.clear
            self.popupContentController.tableView.backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
            self.popupContentController.delegate = self
            self.popupContentController.popupItem.title = "\(self.bikeStations.count) bike stations in total"
            
            if self.popupContentController.bikeStations.count == 0 {
                // self.popupContentController.loadEverything()
            }
            
            targetVC.popupBar.previewingDelegate = self
            targetVC.popupBar.backgroundStyle = UIBlurEffectStyle.extraLight
            targetVC.popupInteractionStyle = .drag
            targetVC.popupContentView.popupCloseButtonStyle = .none
            targetVC.presentPopupBar(withContentViewController: self.popupContentController, animated: true, completion: nil)
            
            let annotations = self.mapView.annotations(in: self.mapView.visibleMapRect)
            self.annotationsInView = Array(annotations)
            self.popupContentController.popupItem.title = "\(self.annotationsInView.count) bike stations near you"
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadStations(completionHandler: @escaping (Bool) -> ()) {
        
        var id = [Int]()
        var name = [String]()
        var location = [CLLocation]()
        var distance = [Double]()
        var address = [String]()
        var capacity = [Int]()
        var nbBikesAvailable = [Int]()
        var nbDisabledBikes = [Int]()
        var nbDocksAvailable = [Int]()
        var nbDisabledDocks = [Int]()
        var isInstalled = [Bool]()
        var isRenting = [Bool]()
        var isReturning = [Bool]()
        var lastUpdated = [String]()
        
        Alamofire.request("https://tor.publicbikesystem.net/ube/gbfs/v1/en/station_information").responseJSON { (Response) in
            
            if let value = Response.result.value {
                
                let json = JSON(value)
                
                let lastDataUpdate = json["last_updated"].doubleValue
                let lastUpdate = Date(timeIntervalSince1970: lastDataUpdate)
                
                for station in json["data"]["stations"].arrayValue {
                    
                    id.append(station["station_id"].intValue)
                    name.append(station["name"].stringValue)
                    let locationToUse = CLLocation(latitude: station["lat"].doubleValue, longitude: station["lon"].doubleValue)
                    location.append(locationToUse)
                    distance.append(locationToUse.distance(from: self.currentLocation))
                    address.append(station["address"].stringValue)
                    capacity.append(station["capacity"].intValue)
                    
                }
                
            }
            
        }
        
        
        Alamofire.request("https://tor.publicbikesystem.net/ube/gbfs/v1/en/station_status").responseJSON { (Response) in
            
            if let value = Response.result.value {
                
                let json = JSON(value)
                
                for station in json["data"]["stations"].arrayValue {
                    
                    let lastDate = Date(timeIntervalSince1970: station["last_reported"].doubleValue)
                    let dateFormatter = DateFormatter()
                    dateFormatter.timeStyle = .short
                    
                    nbBikesAvailable.append(station["num_bikes_available"].intValue)
                    nbDisabledBikes.append(station["num_bikes_disabled"].intValue)
                    nbDocksAvailable.append(station["num_docks_available"].intValue)
                    nbDisabledDocks.append(station["num_docks_disabled"].intValue)
                    isInstalled.append(station["is_installed"].boolValue)
                    isRenting.append(station["is_renting"].boolValue)
                    isReturning.append(station["is_returning"].boolValue)
                    lastUpdated.append(dateFormatter.string(from: lastDate))
                    
                }
                
                for n in 0..<(id.count) {
                    
                    let newStation = BikeStation(id: id[n], name: name[n], location: location[n], distance: distance[n], address: address[n], capacity: capacity[n], nbBikesAvailable: nbBikesAvailable[n], nbDisabledBikes: nbDisabledBikes[n], nbDocksAvailable: nbDocksAvailable[n], nbDisabledDocks: nbDisabledDocks[n], isInstalled: isInstalled[n], isRenting: isRenting[n], isReturning: isReturning[n], lastUpdated: lastUpdated[n])
                    self.bikeStations.append(newStation)
                    
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
            
            return
            
        }
        
        let stationAnnotation = view.annotation as! StationAnnotation
        let views = Bundle.main.loadNibNamed("CalloutView", owner: nil, options: nil)
        let calloutView = views?[0] as! CalloutView
        calloutView.station = stationAnnotation.stationToUse
        calloutView.center = CGPoint(x: view.bounds.size.width / 2, y: -calloutView.bounds.size.height * 0.52)
        calloutView.alpha = 0.0
        
        popupContentController.popupItem.title = stationAnnotation.stationToUse.address
        popupContentController.popupItem.subtitle = "\(stationAnnotation.stationToUse.nbBikesAvailable) bikes available and " + "\(stationAnnotation.stationToUse.nbDocksAvailable) docks available"
        
        UIView.animate(withDuration: 0.3) {
            
            calloutView.alpha = 1.0
            view.addSubview(calloutView)
            
        }
        
        mapView.setCenter((view.annotation?.coordinate)!, animated: true)
        
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        
        self.popupContentController.popupItem.title = "\(self.annotationsInView.count) bike stations near you"
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
                self.popupContentController.popupItem.title = "\(self.annotationsInView.count) bike stations near you"
                
            }
            
        }
        
    }
    
}

