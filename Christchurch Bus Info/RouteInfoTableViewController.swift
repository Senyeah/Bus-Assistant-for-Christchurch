//
//  RouteInfoTableViewController.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 5/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit
import CoreLocation

//"Gardiners Road": ["no": 12345, "stops": [.NumberedRoute("125")]]

var routes: [Dictionary<String, Any>] = [["name": "Gardiners Road", "no": 19416, "stops": [BusLineType.NumberedRoute("125")]],
                                         ["name": "Breens Road", "no": 42857, "stops": [BusLineType.NumberedRoute("125")]],
                                         ["name": "Greers Road", "no": 37462, "stops": [BusLineType.Orbiter(.AntiClockwise), BusLineType.NumberedRoute("125")]],
                                         ["name": "Fake Street", "no": 44196, "stops": [BusLineType.PurpleLine, BusLineType.OrangeLine, BusLineType.BlueLine, BusLineType.YellowLine, BusLineType.NumberedRoute("17"), BusLineType.NumberedRoute("120")]]]

var currentIndex: Int = 0

class RouteInfoTableViewController: UITableViewController, CLLocationManagerDelegate {

    var hasObtainedInitialLocation = false
    var lastLocationUpdated: CLLocation?
    
    var nearestStops: [(StopInformation, CLLocationDistance)] = []
    
    let locationManager = CLLocationManager()
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        
        var distanceMoved: CLLocationDistance = 0.0
        
        if lastLocationUpdated != nil {
            distanceMoved = newLocation.distanceFromLocation(lastLocationUpdated!)
        } else {
            //change me
            locationManager.stopUpdatingLocation()
        }
        
        if distanceMoved > 5 || hasObtainedInitialLocation == false {
            nearestStops = RouteInformationManager.sharedInstance.closestStopsForCoordinate(5, coordinate: locationManager.location!)

            lastLocationUpdated = locationManager.location
            hasObtainedInitialLocation = true
            
            self.tableView.reloadData()
            
            print("\n\nCurrent location: \(locationManager.location!.coordinate)")
            
            for (stop, distance) in nearestStops {
                print("Stop: \(stop.name), no = \(stop.stopNo) distance = \(String(format: "%.2f", distance)) metres")
            }
            print("--------")
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
        
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
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 4
        } else {
            return 2
        }
    }
    
    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        cell.accessoryType = .DisclosureIndicator
        
        let (stopInfo, distance) = nearestStops[indexPath.row]
        
        cell.textLabel!.text = stopInfo.name
        cell.detailTextLabel!.text = String(format: "%.0f metres", distance)
    
        return cell
    }
    */
        
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {

            let cell = tableView.dequeueReusableCellWithIdentifier("GroupHeadingCell", forIndexPath: indexPath)
            cell.textLabel?.text = indexPath.section == 0 ? "Harewood Road" : "Sheffield Crescent"
            
            return cell
        
        } else {
    
            let cell = tableView.dequeueReusableCellWithIdentifier("GroupStopCell", forIndexPath: indexPath) as! BusStopTableViewCell
            
            print("row = \(indexPath.row), section = \(indexPath.section)")
            
            if currentIndex + 1 > routes.count {
                return cell
            }
            
            let currentInfo: Dictionary<String, Any> = routes[currentIndex]
            
            let stops: [BusLineType] = currentInfo["stops"] as! [BusLineType]
            
            cell.stopName.text = currentInfo["name"] as? String
            cell.stopNumber.text = String(currentInfo["no"] as! Int)
            
            cell.setStopLines(stops)
            
            if ++currentIndex > routes.count {
                currentIndex = 0
            }
            
            return cell
            
        }
        
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        struct StaticInstance {
            static var stopInfoSizingCell: UITableViewCell?
            static var headerSizingCell: UITableViewCell?
        }
        
        var cellRequired: UITableViewCell?
        
        if indexPath.row == 0 {
            
            //This means we need sizing for a header
            
            if StaticInstance.headerSizingCell == nil {
                StaticInstance.headerSizingCell = tableView.dequeueReusableCellWithIdentifier("GroupHeadingCell")
            }
            
            cellRequired = StaticInstance.headerSizingCell
            
        } else {
            
            if StaticInstance.stopInfoSizingCell == nil {
                StaticInstance.stopInfoSizingCell = tableView.dequeueReusableCellWithIdentifier("GroupStopCell")
            }
            
            cellRequired = StaticInstance.stopInfoSizingCell
            
        }
        
        //cellRequired!.setNeedsLayout()
        //cellRequired!.layoutIfNeeded()
        
        let size = cellRequired!.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        return size.height + 1.0
        
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
