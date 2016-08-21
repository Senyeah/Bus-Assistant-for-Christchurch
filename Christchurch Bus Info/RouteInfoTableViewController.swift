//
//  RouteInfoTableViewController.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 5/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit
import CoreLocation

let STOPS_TO_LOAD_RADIUS = 500.0
let MIN_UPDATE_DISTANCE_DELTA = 5.0

class RouteInfoTableViewController: UITableViewController, CLLocationManagerDelegate, RouteInformationManagerDelegate {

    let locationManager = CLLocationManager()
    
    var lastLocationUpdated: CLLocation?
    var hasObtainedInitialLocation = false
    
    var nearbyStops: NearbyStopInformation = []
    var favouriteStops: NearbyStopInformation = []
    
    var displayedNumberOfFavouriteStops = 0
    
    func managerReceivedUpdatedInformation(manager: RouteInformationManager) {
        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
    }
    
    func processLocationUpdate() {
        
        nearbyStops.removeAll()
        
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            let currentLocation = CLLocation(latitude: -43.525659, longitude: 172.575630)
        #else
            guard let currentLocation = locationManager.location else {
                return
            }
        #endif

        nearbyStops = RouteInformationManager.sharedInstance.closestStopsForLocation(STOPS_TO_LOAD_RADIUS, location: currentLocation)
        favouriteStops = RouteInformationManager.sharedInstance.nearbyStopInformationForStops(Preferences.favouriteStops, location: currentLocation)
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        
        if newLocation.horizontalAccuracy > 20.0 && nearbyStops.count > 0 {
            return
        }
        
        var distanceMoved: CLLocationDistance = 0.0
        
        if lastLocationUpdated != nil {
            distanceMoved = newLocation.distanceFromLocation(lastLocationUpdated!)
        }
        
        if distanceMoved > MIN_UPDATE_DISTANCE_DELTA || hasObtainedInitialLocation == false {
            
            processLocationUpdate()
            lastLocationUpdated = locationManager.location
            
            hasObtainedInitialLocation = true
            
            if self.nearbyStops.count == 0 && displayedNumberOfFavouriteStops == 0 {
                displayNoStopsNearbyMessage()
            } else {
                tableView.backgroundView = nil
            }
            
            if favouriteStops.count == 0 {
                self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
            } else {
                self.tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, 2)), withRowAnimation: .Automatic)
            }
            
        }
        
    }
    
    func displayBackgroundErrorMessageWithTitle(title: String, errorDetail: String) {
        let messageView = TableViewErrorBackgroundView.initView(title, errorDetail: errorDetail)
        tableView.backgroundView = messageView
    }
    
    func displayNoAuthorisationMessage() {
        displayBackgroundErrorMessageWithTitle("Enable Location Services", errorDetail: "You must enable Location Services in order to determine the bus stops nearest to you.")
    }
    
    func displayNoStopsNearbyMessage() {
        displayBackgroundErrorMessageWithTitle("No Stops Nearby", errorDetail: "No bus stops were found within 500 metres of your location.")
    }
    
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        if status == .Denied || status == .Restricted {
            
            nearbyStops.removeAll()
            tableView.reloadData()
            
            if favouriteStops.count == 0 {
                displayNoAuthorisationMessage()
            }
            
        } else {
            tableView.backgroundView = nil
        }
        
    }
    
    func handleRefresh() {
        
        hasObtainedInitialLocation = false
        processLocationUpdate()
        
        self.refreshControl?.endRefreshing()
        
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        //Do initialisation stuff
        
        locationManager.requestWhenInUseAuthorization()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        locationManager.activityType = .OtherNavigation
        
        RouteInformationManager.sharedInstance.delegate = self
        RouteInformationManager.sharedInstance.initialise()
        
        self.refreshControl?.addTarget(self, action: #selector(handleRefresh), forControlEvents: .ValueChanged)
        
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        favouriteStops = RouteInformationManager.sharedInstance.nearbyStopInformationForStops(Preferences.favouriteStops, location: nil)
        displayedNumberOfFavouriteStops = favouriteStops.count
        
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            processLocationUpdate()
        #endif
        
    }
    
    override func viewWillAppear(animated: Bool) {

        super.viewWillAppear(animated)
        
        if self.tableView.indexPathForSelectedRow != nil {
            self.tableView.deselectRowAtIndexPath(self.tableView.indexPathForSelectedRow!, animated: true)
        }
        
        dispatch_async(dispatch_get_main_queue()) {

            self.tableView.beginUpdates()
            self.favouriteStops = RouteInformationManager.sharedInstance.nearbyStopInformationForStops(Preferences.favouriteStops, location: self.lastLocationUpdated)
            
            if self.favouriteStops.count > 0 {
                
                if self.displayedNumberOfFavouriteStops == 0 {
                    
                    self.tableView.insertSections(NSIndexSet(index: 0), withRowAnimation: .Bottom)
                    
                } else if self.favouriteStops.count > self.displayedNumberOfFavouriteStops {
                    
                    let numberOfFavouritesAdded = self.favouriteStops.count - self.displayedNumberOfFavouriteStops
                    let startIndex = self.displayedNumberOfFavouriteStops
                    
                    let insertedIndexPaths = (startIndex ..< startIndex + numberOfFavouritesAdded).map { row in
                        return NSIndexPath(forRow: row, inSection: 0)
                    }
                    
                    self.tableView.insertRowsAtIndexPaths(insertedIndexPaths, withRowAnimation: .Bottom)
                    
                } else {
                    self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
                }

            } else if self.displayedNumberOfFavouriteStops > 0 {
                self.tableView.deleteSections(NSIndexSet(index: 0), withRowAnimation: .Bottom)
            }
        
            self.displayedNumberOfFavouriteStops = self.favouriteStops.count
            self.tableView.endUpdates()
            
            let canAccessLocation = !(CLLocationManager.authorizationStatus() == .Denied || CLLocationManager.authorizationStatus() == .Restricted)
            
            if canAccessLocation == false && self.displayedNumberOfFavouriteStops == 0 {
                self.displayNoAuthorisationMessage()
            }
            
            if canAccessLocation && self.nearbyStops.count == 0 && self.displayedNumberOfFavouriteStops == 0 {
                self.displayNoStopsNearbyMessage()
            }
            
            if self.displayedNumberOfFavouriteStops > 0 {
                self.tableView.backgroundView = nil
            }
            
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        locationManager.startUpdatingLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return favouriteStops.count > 0 ? 2 : 1
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if favouriteStops.count == 0 {
            return nil
        }
        
        if section == 0 {
            return "Favourite Stops"
        } else {
            return hasObtainedInitialLocation && nearbyStops.count > 0 ? "Nearby Stops" : nil
        }
        
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if favouriteStops.count == 0 {
            return nearbyStops.count
        }
        
        return section == 0 ? favouriteStops.count : nearbyStops.count
        
    }
        
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("GroupStopCell", forIndexPath: indexPath) as! BusStopTableViewCell
        
        var stopInfo: (stop: StopInformation, distance: CLLocationDistance)
        
        if favouriteStops.count > 0 && indexPath.section == 0 {
            stopInfo = favouriteStops[indexPath.row]
            cell.shouldDisplayLocationInformation = hasObtainedInitialLocation
        } else {
            stopInfo = nearbyStops[indexPath.row]
            cell.shouldDisplayLocationInformation = true
        }
        
        cell.stopName.text = RouteInformationManager.sharedInstance.displayStringForStopNumber(stopInfo.stop.stopNo)
        cell.stopNumber.text = String(stopInfo.stop.stopNo)
        
        cell.setDistance(stopInfo.distance)
            
        let stopLinesForStop = RouteInformationManager.sharedInstance.linesForStop(stopInfo.stop.stopTag)
        cell.setStopLines(stopLinesForStop)
        
        cell.layoutIfNeeded()
        
        return cell
        
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 130.0
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        locationManager.stopUpdatingLocation()
        
        let destinationController = segue.destinationViewController as! StopInformationTableViewController
        let indexPath = tableView.indexPathForCell(sender! as! UITableViewCell)!
        
        var stopList: NearbyStopInformation
        
        if indexPath.section == 0 && favouriteStops.count > 0 {
            stopList = favouriteStops
        } else {
            stopList = nearbyStops
        }
        
        let stopInfo = stopList[indexPath.row].stop
        destinationController.stopNumber = stopInfo.stopNo
        
    }

}
