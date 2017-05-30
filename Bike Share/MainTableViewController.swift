//
//  MainTableViewController.swift
//  Bike Share
//
//  Created by Omar Abbasi on 2017-05-03.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import SwiftyJSON
import Alamofire

class BikeStation: NSObject, NSCoding {
    
    var id: Int
    var name: String
    var location: CLLocation
    var distance: Double
    var address: String
    var capacity: Int
    var nbBikesAvailable: Int
    var nbDisabledBikes: Int
    var nbDocksAvailable: Int
    var nbDisabledDocks: Int
    var isInstalled: Bool
    var isRenting: Bool
    var isReturning: Bool
    var lastUpdated: String
    
    init(id: Int, name: String, location: CLLocation, distance: Double, address: String, capacity: Int, nbBikesAvailable: Int, nbDisabledBikes: Int, nbDocksAvailable: Int, nbDisabledDocks: Int, isInstalled: Bool, isRenting: Bool, isReturning: Bool, lastUpdated: String) {
        
        self.id = id
        self.name = name
        self.location = location
        self.distance = distance
        self.address = address
        self.capacity = capacity
        self.nbBikesAvailable = nbBikesAvailable
        self.nbDisabledBikes = nbDisabledBikes
        self.nbDocksAvailable = nbDocksAvailable
        self.nbDisabledDocks = nbDisabledDocks
        self.isInstalled = isInstalled
        self.isRenting = isRenting
        self.isReturning = isReturning
        self.lastUpdated = lastUpdated
        
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        let id = aDecoder.decodeInteger(forKey: "id")
        let name = aDecoder.decodeObject(forKey: "name") as! String
        let location = aDecoder.decodeObject(forKey: "location") as! CLLocation
        let distance = aDecoder.decodeDouble(forKey: "distance")
        let address = aDecoder.decodeObject(forKey: "address") as! String
        let capacity = aDecoder.decodeInteger(forKey: "capacity")
        let nbBikesAvailable = aDecoder.decodeInteger(forKey: "nbBikesAvailable")
        let nbDisabledBikes = aDecoder.decodeInteger(forKey: "nbDisabledBikes")
        let nbDocksAvailable = aDecoder.decodeInteger(forKey: "nbDocksAvailable")
        let nbDisabledDocks = aDecoder.decodeInteger(forKey: "nbDisabledDocks")
        let isInstalled = aDecoder.decodeBool(forKey: "isInstalled")
        let isRenting = aDecoder.decodeBool(forKey: "isRenting")
        let isReturning = aDecoder.decodeBool(forKey: "isReturning")
        let lastUpdated = aDecoder.decodeObject(forKey: "lastUpdated") as! String
        
        self.init(id: id, name: name, location: location, distance: distance, address: address, capacity: capacity, nbBikesAvailable: nbBikesAvailable, nbDisabledBikes: nbDisabledBikes, nbDocksAvailable: nbDocksAvailable, nbDisabledDocks: nbDisabledDocks, isInstalled: isInstalled, isRenting: isRenting, isReturning: isReturning, lastUpdated: lastUpdated)
        
    }
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(id, forKey: "id")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(location, forKey: "location")
        aCoder.encode(distance, forKey: "distance")
        aCoder.encode(address, forKey: "address")
        aCoder.encode(capacity, forKey: "capacity")
        aCoder.encode(nbBikesAvailable, forKey: "nbBikesAvailable")
        aCoder.encode(nbDisabledBikes, forKey: "nbDisabledBikes")
        aCoder.encode(nbDocksAvailable, forKey: "nbDocksAvailable")
        aCoder.encode(nbDisabledDocks, forKey: "nbDisabledDocks")
        aCoder.encode(isInstalled, forKey: "isInstalled")
        aCoder.encode(isRenting, forKey: "isRenting")
        aCoder.encode(isReturning, forKey: "isReturning")
        aCoder.encode(lastUpdated, forKey: "lastUpdated")
        
    }
    
}

protocol SelectedBikeStationDelegate {
    
    func selected(_ bikeStation: BikeStation)
    
}

extension MainTableViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
}

class StationCell: UITableViewCell {
    
    @IBOutlet var stationName: UILabel!
    @IBOutlet var stationDistance: UILabel!
    @IBOutlet var stationCapacity: UILabel!
    @IBOutlet var lastUpdated: UILabel!
    
    var station: BikeStation! {
        
        didSet {
                        
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
            stationDistance.text = "\(distance) away from you"
            stationCapacity.text = "\(station.nbBikesAvailable)"
            lastUpdated.text = "last updated: \(station.lastUpdated)"
            
        }
        
    }
    
}

class MainTableViewController: UITableViewController, UISearchBarDelegate {
    
    var bikeStations = [BikeStation]()
    var filteredBikeStations = [BikeStation]()
    var favouriteBikeStations = [BikeStation]()
    
    var defaults = UserDefaults.standard
    var resultSearchController = UISearchController(searchResultsController: nil)
    var didSelectNewStation = false
    
    var currentLocation = CLLocation()
    let tintColor = UIColor(red:0.06, green:0.81, blue:0.16, alpha:1.0)
    
    var delegate: SelectedBikeStationDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // loadEverything()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        
        get {
            
            return .slide
            
        }
        
    }
    
    func loadEverything() {
        
        setupTheme()
        
        currentLocation = CLLocation(latitude: 43.6628917, longitude: -79.39565640000001)
        
        loadStations { (success) in
            
            if success {
                
                self.makeStations()
                self.loadFavourites()
                
            }
            
        }
        
    }
    
    func loadFavourites() {
        
        if self.defaults.object(forKey: "favourites") == nil {
            
            self.tableView.reloadData()
            
        } else {
            
            // favs are there, decode array, append to it, encode it, then archive and send to UserDefaults
            
            if let decodedArr = self.defaults.object(forKey: "favourites") as? Data {
                
                if let decodedStations = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [BikeStation] {
                    
                    self.favouriteBikeStations = decodedStations
                    
                    self.tableView.reloadData()
                    
                }
                
            }
        
        }
        
    }
    
    func setupTheme() {
        
        self.resultSearchController = ({
            
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()
            controller.searchBar.searchBarStyle = UISearchBarStyle.minimal
            controller.searchBar.isTranslucent = true
            controller.searchBar.tintColor = self.tintColor
            let textSearchBar = controller.searchBar.value(forKey: "searchField") as? UITextField
            textSearchBar?.textColor = UIColor.black
            let placeholderTextSearchBar = textSearchBar!.value(forKey: "placeholderLabel") as? UILabel
            placeholderTextSearchBar?.textColor = UIColor.lightGray
            let glassIconView = textSearchBar?.leftView as! UIImageView
            glassIconView.tintColor = UIColor.lightGray
            
            self.tableView.tableHeaderView = controller.searchBar
            
            return controller
            
        })()
        self.tableView.reloadData()
        
        definesPresentationContext = true
        
        let searchOffset = CGPoint(x: 0, y: 44)
        tableView.setContentOffset(searchOffset, animated: false)
        
        self.title = "BikeShare"
        self.navigationController?.navigationBar.tintColor = tintColor
        
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
        
        DispatchQueue.main.async {
            
            self.tableView.reloadData()
            
        }
        
    }
    
    func filterContentForSearchText(searchText: String) {
        
        filteredBikeStations = bikeStations.filter({ (station) -> Bool in
            return station.address.lowercased().contains(searchText.lowercased())
        })
        self.tableView.reloadData()
        
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if self.resultSearchController.isActive {
            self.resultSearchController.isActive = false
            self.resultSearchController.resignFirstResponder()
        }
        
        /*
        
        if self.resultSearchController.isActive {
            self.resultSearchController.searchBar.searchBarStyle = UISearchBarStyle.default
            self.resultSearchController.searchBar.barTintColor = UIColor.white
            self.resultSearchController.searchBar.layer.borderColor = UIColor.clear.cgColor
            
            for subview in self.resultSearchController.searchBar.subviews {
                
                for view in subview.subviews {
                    
                    if view.isKind(of: NSClassFromString("UINavigationButton")!) {
                        
                        let cancelBtn = view as! UIButton
                        cancelBtn.setTitleColor(self.tintColor, for: .normal)
                        
                    }
                    
                }
                
            }
            
        }
        
        if !(self.resultSearchController.isActive) {
            self.resultSearchController.searchBar.searchBarStyle = UISearchBarStyle.minimal
        }
        
        self.resultSearchController.searchBar.resignFirstResponder()
        
        */
 
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        if tableView.numberOfSections > 1 {
            
            if indexPath.section == 0 {
                
                let delete = UITableViewRowAction(style: .destructive, title: "Delete", handler: { (action, index) in
                    
                    self.favouriteBikeStations.remove(at: index.row)
                    if let decodedArr = self.defaults.object(forKey: "favourites") as? Data {
                        
                        if var decodedStations = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [BikeStation] {
                            
                            decodedStations.remove(at: index.row)
                            
                            self.tableView.reloadData()
                            
                            let encode: Data = NSKeyedArchiver.archivedData(withRootObject: decodedStations)
                            self.defaults.set(encode, forKey: "favourites")
                            self.defaults.synchronize()
                            
                        }
                        
                    }
                    
                    self.tableView.reloadData()
                    
                })
                
                delete.backgroundColor = UIColor.red
                
                return [delete]
                
                
            } else {
                
                let favourite = UITableViewRowAction(style: .normal, title: "Favourite") { (action, index) in
                    
                    if self.favouriteBikeStations.contains(where: { $0.id == self.bikeStations[index.row].id }) {
                        
                        // already has it in here
                        
                        self.tableView.reloadData()
                        
                    } else {
                        
                        self.favouriteBikeStations.append(self.bikeStations[index.row])
                        
                        if self.defaults.object(forKey: "favourites") == nil {
                            
                            // no favs, encode arr and replace
                            
                            let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: self.favouriteBikeStations)
                            self.defaults.set(encodedData, forKey: "favourites")
                            self.defaults.synchronize()
                            
                            self.tableView.reloadData()
                            
                        } else {
                            
                            // favs are there, decode array, append to it, encode it, then archive and send to UserDefaults
                            
                            if let decodedArr = self.defaults.object(forKey: "favourites") as? Data {
                                
                                if var decodedStations = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [BikeStation] {
                                    
                                    if !(decodedStations.contains(where: { $0.id == self.bikeStations[index.row].id })) {
                                        
                                        decodedStations.append(self.bikeStations[index.row])
                                        
                                        let alert = UIAlertController(title: "Added To Favourites", message: "Successfully added in your favourites!", preferredStyle: .alert)
                                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                                        self.present(alert, animated: true, completion: nil)
                                        
                                    } else {
                                        
                                        let alert = UIAlertController(title: "Already In Favourites", message: "The Bike Station you are trying to add is already in your favourites.", preferredStyle: .alert)
                                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                                        self.present(alert, animated: true, completion: nil)
                                        
                                    }
                                    
                                    print(decodedStations)
                                    print(self.favouriteBikeStations)
                                    
                                    self.tableView.reloadData()
                                    
                                    let encode: Data = NSKeyedArchiver.archivedData(withRootObject: decodedStations)
                                    self.defaults.set(encode, forKey: "favourites")
                                    self.defaults.synchronize()
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                    // TODO:
                    // Use code from EatWhat for multiple sections
                    
                }
                
                favourite.backgroundColor = UIColor.blue
                
                
                return [favourite]
                
            }
            
        } else {
            
            let favourite = UITableViewRowAction(style: .normal, title: "Favourite") { (action, index) in
                
                if self.favouriteBikeStations.contains(where: { $0.id == self.bikeStations[index.row].id }) {
                    
                    // already has it in here
                    
                    self.tableView.reloadData()
                    
                } else {
                    
                    self.favouriteBikeStations.append(self.bikeStations[index.row])
                    
                    if self.defaults.object(forKey: "favourites") == nil {
                        
                        // no favs, encode arr and replace
                        
                        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: self.favouriteBikeStations)
                        self.defaults.set(encodedData, forKey: "favourites")
                        self.defaults.synchronize()
                        
                        self.tableView.reloadData()
                        
                    } else {
                        
                        // favs are there, decode array, append to it, encode it, then archive and send to UserDefaults
                        
                        if let decodedArr = self.defaults.object(forKey: "favourites") as? Data {
                            
                            if var decodedStations = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [BikeStation] {
                                
                                if !(decodedStations.contains(where: { $0.id == self.bikeStations[index.row].id })) {
                                    
                                    decodedStations.append(self.bikeStations[index.row])
                                    
                                    let alert = UIAlertController(title: "Added To Favourites", message: "Successfully added in your favourites!", preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                                    self.present(alert, animated: true, completion: nil)
                                    
                                } else {
                                    
                                    let alert = UIAlertController(title: "Already In Favourites", message: "The Bike Station you are trying to add is already in your favourites.", preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                                    self.present(alert, animated: true, completion: nil)
                                    
                                }
                                
                                print(decodedStations)
                                print(self.favouriteBikeStations)
                                
                                self.tableView.reloadData()
                                
                                let encode: Data = NSKeyedArchiver.archivedData(withRootObject: decodedStations)
                                self.defaults.set(encode, forKey: "favourites")
                                self.defaults.synchronize()
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
                // TODO:
                // Use code from EatWhat for multiple sections
                
            }
            
            favourite.backgroundColor = UIColor.blue
            
            
            return [favourite]
            
        }
        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if tableView.numberOfSections > 1 {
            
            if section == 0 {
                
                return "FAVOURITES"
                
            } else {
                
                return "ALL BIKE STATIONS"
                
            }
            
        } else {
            
            return "ALL BIKE STATIONS"
            
        }
        
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if self.favouriteBikeStations.count > 0 {
            
            return 2
            
        } else {
            
            return 1
            
        }
        
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.resultSearchController.isActive {
            
            return self.filteredBikeStations.count
            
        } else {
            
            if tableView.numberOfSections > 1 {
                
                if section == 0 {
                    
                    return self.favouriteBikeStations.count
                    
                } else {
                    
                    return self.bikeStations.count
                    
                }
                
            } else {
                
                return self.bikeStations.count
                
            }
            
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        // popupItem.title = self.bikeStations[indexPath.row].address
        // popupItem.subtitle = "\(self.bikeStations[indexPath.row].nbBikesAvailable)" + " bikes available and " + "\(self.bikeStations[indexPath.row].nbDocksAvailable)" + " docks available"
        
        if let del = delegate {
            
            if self.resultSearchController.isActive {
                del.selected(self.filteredBikeStations[indexPath.row])
            } else {
                del.selected(self.bikeStations[indexPath.row])
            }
            
        }
        
        popupPresentationContainer?.closePopup(animated: true, completion: { 
            
            self.didSelectNewStation = true
            
        })
        
        if self.resultSearchController.isActive {
            self.resultSearchController.isActive = false
            self.resultSearchController.resignFirstResponder()
        }
        
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! StationCell

        // Configure the cell...
        
        if self.resultSearchController.isActive {
            
            cell.station = self.filteredBikeStations[indexPath.row]
            
        } else {
            
            if tableView.numberOfSections > 1 {
                
                if indexPath.section == 0 {
                    
                    cell.station = self.favouriteBikeStations[indexPath.row]
                    
                } else {
                    
                    cell.station = self.bikeStations[indexPath.row]
                    
                }
                
            } else {
                
                cell.station = self.bikeStations[indexPath.row]
                
            }
            
        }

        return cell
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "showDetailMap" {
            
            if let indexPath = self.tableView.indexPathForSelectedRow {
                
                let stationDetail: BikeStation
                
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailTableViewController
                
                // for when implementing searchBar
                if resultSearchController.isActive {
                
                    stationDetail = filteredBikeStations[indexPath.row]
                    
                } else {
                    
                    stationDetail = bikeStations[indexPath.row]
                    
                }
                
                controller.station = stationDetail
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                
            }
            
        }
        
    }

}
