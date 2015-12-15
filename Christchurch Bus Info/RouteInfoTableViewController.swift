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
    
    var groupedStops: [String: [String]] = [:]
    var distanceFromStop: [String: CLLocationDistance] = [:]
    
    func managerReceivedUpdatedInformation(manager: RouteInformationManager) {
        self.tableView.reloadData()
    }
    
    func processLocationUpdate() {
        
        groupedStops = [:]
        
        guard let currentLocation = locationManager.location else {
            return
        }
        
        let nearestStops = RouteInformationManager.sharedInstance.closestStopsForLocation(STOPS_TO_LOAD_RADIUS, location: currentLocation)
        
        var groupOrdering: [String] = []
        
        for (stop, distance) in nearestStops {
            
            if groupedStops[stop.roadName] == nil {
                groupedStops[stop.roadName] = []
            }
            
            groupedStops[stop.roadName]!.append(stop.stopNo)
            
            if groupOrdering.contains(stop.roadName) == false {
                groupOrdering.append(stop.roadName)
            }
            
            distanceFromStop[stop.stopNo] = distance
            
        }
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        
        var distanceMoved: CLLocationDistance = 0.0
        
        if lastLocationUpdated != nil {
            distanceMoved = newLocation.distanceFromLocation(lastLocationUpdated!)
        }
        
        if distanceMoved > MIN_UPDATE_DISTANCE_DELTA || hasObtainedInitialLocation == false {
            
            processLocationUpdate()
            lastLocationUpdated = locationManager.location
            
            hasObtainedInitialLocation = true
            
            self.tableView.reloadData()
            
        }
        
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        locationManager.requestWhenInUseAuthorization()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        RouteInformationManager.sharedInstance.delegate = self
        RouteInformationManager.sharedInstance.initialise()
                
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
        // Dispose of any resources that can be recreated.
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return groupedStops.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let key = Array(groupedStops.keys)[section]
        return groupedStops[key]!.count + 1
        
    }
        
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {

            let cell = tableView.dequeueReusableCellWithIdentifier("GroupHeadingCell", forIndexPath: indexPath)
            cell.textLabel?.text = Array(groupedStops.keys)[indexPath.section]
            
            return cell
        
        } else {
    
            let cell = tableView.dequeueReusableCellWithIdentifier("GroupStopCell", forIndexPath: indexPath) as! BusStopTableViewCell
            
            let groupName = Array(groupedStops.keys)[indexPath.section]
            let stopNumber = groupedStops[groupName]![indexPath.row - 1] 
            
            let stopInfo = RouteInformationManager.sharedInstance.stopInformationForStopNumber(stopNumber)!
            
            cell.stopName.text = stopInfo.name
            cell.stopNumber.text = String(stopNumber)
            
            cell.setDistance(distanceFromStop[stopNumber]!)
            
            let stopLinesForStop = RouteInformationManager.sharedInstance.linesForStop(stopInfo.stopTag)
            cell.setStopLines(stopLinesForStop)
            
            cell.layoutSubviews()
            
            return cell
            
        }
        
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        locationManager.stopUpdatingLocation()
        
        let destinationController = segue.destinationViewController as! StopInformationTableViewController
        let indexPath = tableView.indexPathForCell(sender! as! UITableViewCell)!
        
        let groupName = Array(groupedStops.keys)[indexPath.section]
        destinationController.stopNumber = groupedStops[groupName]![indexPath.row - 1] 
        
    }

}
