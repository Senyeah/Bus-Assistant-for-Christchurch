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

var currentIndex: Int = 0

class RouteInfoTableViewController: UITableViewController, CLLocationManagerDelegate, RouteInformationManagerDelegate {

    let locationManager = CLLocationManager()
    
    var lastLocationUpdated: CLLocation?
    var hasObtainedInitialLocation = false
    
    var nearbyStops: NearbyStopInformation = []
    var distanceFromStop: [String: CLLocationDistance] = [:]
    
    func managerReceivedUpdatedInformation(manager: RouteInformationManager) {
        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
    }
    
    func processLocationUpdate() {
        
        nearbyStops.removeAll()
        
        guard let currentLocation = locationManager.location else {
            return
        }
        
        nearbyStops = RouteInformationManager.sharedInstance.closestStopsForLocation(STOPS_TO_LOAD_RADIUS, location: currentLocation)
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        
        if newLocation.horizontalAccuracy >= 65.0 && nearbyStops.count > 0 {
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
            
            if self.nearbyStops.count == 0 {
                let noStopsMessage = TableViewErrorBackgroundView.initView("No Bus Stops Nearby", errorDetail: "No bus stops were found within 500 metres of your location.")
                tableView.backgroundView = noStopsMessage
            } else {
                tableView.backgroundView = nil
            }
            
            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
            
        }
        
    }
    
    func displayNoAuthorisationMessage() {
        let noStopsMessage = TableViewErrorBackgroundView.initView("Enable Location Services", errorDetail: "You must enable Location Services in order to determine the bus stops nearest to you.")
        tableView.backgroundView = noStopsMessage
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        if status == .Denied || status == .Restricted {
            nearbyStops.removeAll()
            tableView.reloadData()
            
            displayNoAuthorisationMessage()
        } else {
            tableView.backgroundView = nil
        }
        
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
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        if CLLocationManager.authorizationStatus() == .Denied || CLLocationManager.authorizationStatus() == .Restricted {
            displayNoAuthorisationMessage()
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {

        super.viewWillAppear(animated)
        
        if self.tableView.indexPathForSelectedRow != nil {
            self.tableView.deselectRowAtIndexPath(self.tableView.indexPathForSelectedRow!, animated: true)
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
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nearbyStops.count
    }
        
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("GroupStopCell", forIndexPath: indexPath) as! BusStopTableViewCell
            
        let stopInfo = nearbyStops[indexPath.row]
        
        cell.stopName.text = "\(stopInfo.stop.roadName) near \(stopInfo.stop.name)"
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
        
        let stopInfo = nearbyStops[indexPath.row].stop
        destinationController.stopNumber = stopInfo.stopNo
        
    }

}
