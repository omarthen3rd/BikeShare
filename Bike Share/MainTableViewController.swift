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

public extension Int {
    /// returns number of digits in Int number
    public var digitCount: Int {
        get {
            return numberOfDigits(in: self)
        }
    }
    /// returns number of useful digits in Int number
    public var usefulDigitCount: Int {
        get {
            var count = 0
            for digitOrder in 0..<self.digitCount {
                /// get each order digit from self
                let digit = self % (Int(pow(10, digitOrder + 1) as NSDecimalNumber))
                    / Int(pow(10, digitOrder) as NSDecimalNumber)
                if isUseful(digit) { count += 1 }
            }
            return count
        }
    }
    // private recursive method for counting digits
    private func numberOfDigits(in number: Int) -> Int {
        if abs(number) < 10 {
            return 1
        } else {
            return 1 + numberOfDigits(in: number/10)
        }
    }
    // returns true if digit is useful in respect to self
    private func isUseful(_ digit: Int) -> Bool {
        return (digit != 0) && (self % digit == 0)
    }
}

extension NSMutableAttributedString {
    
    func setColorForText(_ textToFind: String, with color: UIColor) {
        let range = self.mutableString.range(of: textToFind, options: .caseInsensitive)
        if range.location != NSNotFound {
            addAttribute(NSForegroundColorAttributeName, value: color, range: range)
        }
    }
    
    func setColorForRange(_ range: NSRange, with color: UIColor) {
        if range.location != NSNotFound {
            addAttribute(NSForegroundColorAttributeName, value: color, range: range)
        }
    }
    
    func setBoldForText(_ textToFind: String) {
        let range = self.mutableString.range(of: textToFind, options: .caseInsensitive)
        if range.location != NSNotFound {
            let attrs = [NSFontAttributeName : UIFont.systemFont(ofSize: 19, weight: UIFontWeightSemibold)]
            addAttributes(attrs, range: range)
        }
        
    }
    
    func setSizeForText(_ textToFind: String, with size: CGFloat) {
        let range = self.mutableString.range(of: textToFind, options: .caseInsensitive)
        if range.location != NSNotFound {
            let attrs = [NSFontAttributeName : UIFont.systemFont(ofSize: size)]
            addAttributes(attrs, range: range)
        }
        
    }
    
}

extension UIColor {
    
    static let specialGreen = UIColor(red: 0.00, green: 0.78, blue: 0.00, alpha: 1.0)
    
}

class BikeStation: NSObject, NSCoding {
    
    var id = 0
    var name = ""
    var location = CLLocation()
    var distance = 0.0
    var address = ""
    var capacity = 0
    var nbBikesAvailable = 0
    var nbDisabledBikes = 0
    var nbDocksAvailable = 0
    var nbDisabledDocks = 0
    var isInstalled = false
    var isRenting = false
    var isReturning = false
    var lastUpdated = ""
    
    init(id: Int, name: String, location: CLLocation, distance: Double, address: String, capacity: Int) {
        
        self.id = id
        self.name = name
        self.location = location
        self.distance = distance
        self.address = address
        self.capacity = capacity
        
    }
    
    init(nbBikesAvailable: Int, nbDisabledBikes: Int, nbDocksAvailable: Int, nbDisabledDocks: Int, isInstalled: Bool, isRenting: Bool, isReturning: Bool, lastUpdated: String) {

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
        
        self.init(id: id, name: name, location: location, distance: distance, address: address, capacity: capacity)
        
    }
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(id, forKey: "id")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(location, forKey: "location")
        aCoder.encode(distance, forKey: "distance")
        aCoder.encode(address, forKey: "address")
        aCoder.encode(capacity, forKey: "capacity")
        
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
            
            // Start attributed label for capacity
            
            // get range of text to colour
            let textColorRange_bikes = NSRange(location: 0, length: station.nbBikesAvailable.digitCount)
            let textColorRange_docks = NSRange(location: station.nbBikesAvailable.digitCount + 9, length: station.nbDocksAvailable.digitCount)
            let multipleText = "\(station.nbBikesAvailable) bikes · \(station.nbDocksAvailable) open docks"
            
            let attributedString = NSMutableAttributedString(string: multipleText)
            attributedString.setColorForRange(textColorRange_bikes, with: UIColor.specialGreen)
            attributedString.setBoldForText("\(station.nbBikesAvailable)")
            attributedString.setColorForRange(textColorRange_docks, with: UIColor.specialGreen)
            attributedString.setBoldForText("\(station.nbDocksAvailable)")
            
            stationDistance.attributedText = attributedString
            
            // End attributed label
            
            stationCapacity.text = "\(distance) away · updated at \(station.lastUpdated)"
            
        }
        
    }
    
}

class MainTableViewController: UITableViewController, UISearchBarDelegate {
    
    var bikeStations = [BikeStation]()
    var filteredBikeStations = [BikeStation]()
    var favouriteBikeStations = [BikeStation]()
    var favouriteBikeStationIDs = [Int]()
    
    var defaults = UserDefaults.standard
    var resultSearchController = UISearchController(searchResultsController: nil)
    var didSelectNewStation = false
    
    var currentLocation = CLLocation()
    let tintColor = UIColor(red:0.06, green:0.81, blue:0.16, alpha:1.0)
    
    var delegate: SelectedBikeStationDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // call func to load everything
        loadEverything()
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
        
        print(favouritesExists())
        
        // setup ui for view
        setupTheme()
        
        // set current location to U of T (for testing)
        currentLocation = CLLocation(latitude: 43.6628917, longitude: -79.39565640000001)
        
        // main func for calling both 'loadStationInformation' and 'loadStationStatus'
        loadFavourites()
        loadStations { (_) in
            
            // after func is completed, organize stations by distance
            self.makeStations()
            
        }
        
    }
    
    // load favourites from UserDefaults
    func loadFavourites() {
        
        // checks if favourites exist in UserDefaults by checking for nil value
        let favouritesExist = self.defaults.object(forKey: "favourites") != nil
        
        if favouritesExist {
            
            // favs are there, decode array and assign to favouriteBikeStationIDs
            
            // access Data object from UserDefaults with key "favourites" and assign to variable 'decodedArr'
            guard let decodedArr = self.defaults.object(forKey: "favourites") as? Data else { return }
            // unarchive 'decodedArr' and typecast [Int] and assign to variable 'decodedStations'
            guard let decodedStations = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [Int] else { return }
            // assign 'favouriteBikeStationIDs' to 'decodedStations'
            self.favouriteBikeStationIDs = decodedStations
        
        } else {
            
            // no favs, encode arr and replace with empty one
            
            let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: self.favouriteBikeStationIDs)
            self.defaults.set(encodedData, forKey: "favourites")
            self.defaults.synchronize()
            
        }
        
    }
    
    func favouritesExists() -> Bool {
        
        // access Data object from UserDefaults with key "favourites" and assign to variable 'decodedArr'
        guard let decodedArr = self.defaults.object(forKey: "favourites") as? Data else { return false }
        // unarchive 'decodedArr' and typecast [Int] and assign to variable 'decodedStations'
        guard let _ = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [Int] else { return false }
        return true
        
    }
    
    func addToFavourites(_ id: Int) {
        // take id from favouriteBikeStationIDs -> add to UserDefaults
        
        self.favouriteBikeStationIDs.append(id)
        
        // access Data object from UserDefaults with key "favourites" and assign to variable 'decodedArr'
        guard let decodedArr = self.defaults.object(forKey: "favourites") as? Data else { return }
        // unarchive 'decodedArr' and typecast [Int] and assign to variable 'decodedStations'
        guard var decodedStations = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [Int] else { return }
        // assign 'decodedStations' to 'favouriteBikeStationIDs'
        decodedStations = self.favouriteBikeStationIDs
        
        self.tableView.reloadData()
        
        // re-encode object and add to UserDefaults
        let encode: Data = NSKeyedArchiver.archivedData(withRootObject: decodedStations)
        self.defaults.set(encode, forKey: "favourites")
        self.defaults.synchronize()
        
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
            
            let blurryBG = UIView(frame: controller.searchBar.frame)
            blurryBG.backgroundColor = UIColor.clear
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = controller.searchBar.frame
            blurryBG.addSubview(blurView)
            
            controller.searchBar.insertSubview(blurryBG, at: 0)
            
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
        
        let blurEffect = UIBlurEffect(style: .extraLight)
        tableView.separatorEffect = UIVibrancyEffect(blurEffect: blurEffect)
        
        self.title = "BikeShare"
        self.navigationController?.navigationBar.tintColor = tintColor
        
    }
    
    // func to load both station information/status func together
    func loadStations(completionHandler: @escaping (Bool) -> ()) {
        
        loadStationInformation { (success) in
            
            self.loadStationStatus(completionHandler: { (success) in
                
                completionHandler(true)
                
            })
            
        }
        
    }
    
    // loads station information (id, name, static intersection (location), distance, address, capacity)
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
                    
                    // add station to either array to avoid repetition
                    if self.favouriteBikeStationIDs.contains(id) {
                        self.favouriteBikeStations.append(newStation)
                    } else {
                        self.bikeStations.append(newStation)
                    }
                    
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
                    
                    let lastDate = Date(timeIntervalSince1970: station["last_reported"].doubleValue)
                    let dateFormatter = DateFormatter()
                    dateFormatter.timeStyle = .short
                    
                    let stationID = station["station_id"].intValue
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
                    
                    if self.favouriteBikeStations.contains(where: { $0.id == stationID }) {
                        
                        let index = self.favouriteBikeStations.index(where: { $0.id == stationID })
                        let favStation = self.favouriteBikeStations[index as! Int]
                        favStation.nbBikesAvailable = nbBikesAvailable
                        favStation.nbDisabledBikes = nbDisabledBikes
                        favStation.nbDocksAvailable = nbDocksAvailable
                        favStation.nbDisabledDocks = nbDisabledDocks
                        favStation.isInstalled = isInstalled
                        favStation.isRenting = isRenting
                        favStation.isReturning = isReturning
                        favStation.lastUpdated = lastUpdated
                        
                    }
                    
                    stationsIndex += 1
                    
                }
                
                completionHandler(true)
                
            }
            
        }
        
    }
    
    func makeStations() {
        
        // sort closest distance on the top
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
    
    private var lastContentOffset: CGFloat = 0
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if self.lastContentOffset > scrollView.contentOffset.y {
            
            if self.resultSearchController.isActive {
                
                self.resultSearchController.isActive = false
                self.resultSearchController.resignFirstResponder()
                
            }
            
            // scrolling up
            
        }
         
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        if tableView.numberOfSections > 1 {
            // favourites already exists with all bike stations
            
            if indexPath.section == 0 {
                // actions in 'favourites' section
                // action is to 'delete'
                // ---> remove from favouriteBikeStation object, remove from favouriteBikeStationIDs array -> replace UserDefaults array with
                // updated favouriteBikeStationIDs
                
                let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (_, index) in
                    
                    self.favouriteBikeStations.remove(at: index.row)
                    self.favouriteBikeStationIDs.remove(at: index.row)
                    
                    // access Data object from UserDefaults with key "favourites" and assign to variable 'decodedArr'
                    guard let decodedArr = self.defaults.object(forKey: "favourites") as? Data else { return }
                    // unarchive 'decodedArr' and typecast [Int] and assign to variable 'decodedStations'
                    guard var decodedStations = NSKeyedUnarchiver.unarchiveObject(with: decodedArr) as? [Int] else { return }
                    decodedStations = self.favouriteBikeStationIDs
                    
                    let encode: Data = NSKeyedArchiver.archivedData(withRootObject: decodedStations)
                    self.defaults.set(encode, forKey: "favourites")
                    self.defaults.synchronize()
                    
                    self.tableView.reloadData()
                    
                }
                
                deleteAction.backgroundColor = .red
                
                return [deleteAction]
                
            } else {
                // actions in 'all bike stations' section
                // action is to favourite
                
                let favouriteAction = UITableViewRowAction(style: .default, title: "Favourite") { (_, index) in
                    
                    let stationID = self.bikeStations[index.row].id
                    
                    self.favouriteBikeStations.append(self.bikeStations[index.row])
                    // remove from current bikeStation array to avoid repetition of stations
                    self.bikeStations.remove(at: index.row)
                    // func takes care of adding station to favourites
                    self.addToFavourites(stationID)
                    
                    self.tableView.reloadData()
                    
                }
                
                favouriteAction.backgroundColor = .blue
                
                return [favouriteAction]
                
            }
            
        } else {
            // actions in 'all bike stations' section
            // action is to favourite
            
            let favouriteAction = UITableViewRowAction(style: .default, title: "Favourite") { (_, index) in
                
                let stationID = self.bikeStations[index.row].id
                
                self.favouriteBikeStations.append(self.bikeStations[index.row])
                // remove from current bikeStation array to avoid repetition of stations
                self.bikeStations.remove(at: index.row)
                // func takes care of adding station to favourites
                self.addToFavourites(stationID)
                
                self.tableView.reloadData()
                
            }
            
            favouriteAction.backgroundColor = .blue
            
            return [favouriteAction]
            
        }
        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if tableView.numberOfSections > 1 {
            
            if self.resultSearchController.isActive {
                
                return "ALL BIKE STATIONS"
                
            } else if section == 0 {
                
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
            
            if self.resultSearchController.isActive {
                
                return 1
                
            } else {
                
                return 2
                
            }
            
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
        
        if let del = delegate {
            
            if self.resultSearchController.isActive {
                del.selected(self.filteredBikeStations[indexPath.row])
            } else {
                
                if tableView.numberOfSections > 1 {
                    
                    if indexPath.section == 0 {
                        
                        del.selected(self.favouriteBikeStations[indexPath.row])
                        
                    } else {
                        
                        del.selected(self.bikeStations[indexPath.row])
                        
                    }
                    
                } else {
                    
                    del.selected(self.bikeStations[indexPath.row])
                    
                }
                
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
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
                
                if resultSearchController.isActive {
                
                    stationDetail = filteredBikeStations[indexPath.row]
                    
                } else {
                    
                    if tableView.numberOfSections > 1 {
                        
                        if indexPath.section == 0 {
                            
                            stationDetail = favouriteBikeStations[indexPath.row]
                            
                        } else {
                            
                            stationDetail = bikeStations[indexPath.row]
                            
                        }
                        
                    } else {
                        
                        stationDetail = bikeStations[indexPath.row]
                        
                    }

                    
                }
                
                controller.station = stationDetail
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                
            }
            
        }
        
    }

}
