//
//  RouteInfoTableViewController.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 5/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit
import CoreLocation

let NEAREST_STOPS_TO_LOAD = 5

var currentIndex: Int = 0

class RouteInfoTableViewController: UITableViewController, CLLocationManagerDelegate {

    let locationManager = CLLocationManager()
    
    var hasObtainedInitialLocation = false
    var lastLocationUpdated: CLLocation?

    var groupedStops = [String: NSMutableArray]()
    var distanceFromStop = [String: CLLocationDistance]()
    
    func processLocationUpdate() {
        
        groupedStops = [:]
        
        let nearestStops = RouteInformationManager.sharedInstance.closestStopsForCoordinate(NEAREST_STOPS_TO_LOAD, coordinate: locationManager.location!)
        
        var groupOrdering: [String] = []
        
        for (stop, distance) in nearestStops {
            
            if groupedStops[stop.roadName] == nil {
                groupedStops[stop.roadName] = NSMutableArray()
            }
            
            groupedStops[stop.roadName]!.addObject(stop.stopNo)
            
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
        } else {
            //change me
          //  locationManager.stopUpdatingLocation()
        }
        
        if distanceMoved > 5 || hasObtainedInitialLocation == false {
            
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
            let stopNumber = groupedStops[groupName]![indexPath.row - 1] as! String
            
            let stopInfo: StopInformation = RouteInformationManager.sharedInstance.stopInformationForStopNumber(stopNumber)!
            
            cell.stopName.text = stopInfo.name
            cell.stopNumber.text = String(stopNumber)
            
            cell.setDistance(distanceFromStop[stopNumber]!)
            
            cell.setStopLines(stopInfo.lines)
            
            return cell
            
        }
        
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        let destinationController = segue.destinationViewController as! StopInformationTableViewController
        let indexPath = tableView.indexPathForCell(sender! as! UITableViewCell)!
        
        let groupName = Array(groupedStops.keys)[indexPath.section]
        destinationController.stopNumber = groupedStops[groupName]![indexPath.row - 1] as! String
        
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
}
