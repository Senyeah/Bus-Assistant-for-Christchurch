//
//  StopInformationTableViewController.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 14/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

let ARRIVING_BUSES_SECTION = 0
let UPDATE_FREQUENCY_SECONDS = 30.0

let MIN_THUMBNAIL_WIDTH = 30.0
let DEFAULT_SEPARATOR_INSET = 60.0

class StopInformationTableViewController: UITableViewController, StopInformationParserDelegate {
    
    var stopNumber: String!
    var stopInfoParser: StopInformationParser!
    
    var lineLabelWidth = CGFloat(30.0)
    var cellContentInset = CGFloat(0.0)
    
    var busArrivalInfo: [[String : AnyObject]] = [] {
        
        didSet {
            
            let prototypeLineLabelView = BusLineLabelView(lineType: .NumberedRoute(""))
            var maxWidth = CGFloat(0.0)
            
            for item in busArrivalInfo {
                
                let lineType = RouteInformationManager.sharedInstance.busLineTypeForString(item["route_no"]! as! String)
                prototypeLineLabelView.setLineType(lineType)
                
                if prototypeLineLabelView.widthConstraint.constant > maxWidth {
                    maxWidth = prototypeLineLabelView.widthConstraint.constant
                    cellContentInset = 30 + maxWidth
                }
                
            }
            
            lineLabelWidth = maxWidth
            
        }
        
    }
    
    var hasReceivedInfo = false
    var infoUpdateTimer: NSTimer!
    
    var separatorInset = CGFloat(DEFAULT_SEPARATOR_INSET)
    var routeThumbnailWidth = CGFloat(MIN_THUMBNAIL_WIDTH)
    
    func formattedStringForArrivalTime(minutes: Int) -> String {

        let hoursAway = Int(floor(Double(minutes / 60)))
        var minutesAway = minutes
        
        var returnString: String = ""
        
        if hoursAway > 0 {
            minutesAway %= 60
            
            returnString = "\(hoursAway) hour"
            
            if hoursAway > 1 {
                returnString += "s"
            }
            
            returnString += " "
        }
        
        if minutesAway > 1 {
            returnString += "\(minutesAway) minutes"
        } else if minutesAway == 1 {
            returnString += "1 minute"
        } else if minutesAway == 0 && hoursAway == 0 {
            returnString = "Now"
        }
        
        return returnString
        
    }
    

    func stopInformationParser(parser: StopInformationParser, didReceiveStopInformation info: [[String : AnyObject]]) {
        
        //Weird things happen if you don't update the UI on the main thread
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.busArrivalInfo = info
            self.hasReceivedInfo = true
            
            self.tableView.reloadData()
            
        })
        
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.layoutMargins = UIEdgeInsets(top: 0.0, left: cellContentInset, bottom: 0.0, right: 0.0)
    }
    
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, busArrivalInfo.count)
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if busArrivalInfo.count == 0 {
            
            let cell = tableView.dequeueReusableCellWithIdentifier("RouteStopIndeterminateCell", forIndexPath: indexPath) as! RouteStopIndeterminateTableViewCell
            
            if hasReceivedInfo {
                cell.titleLabel.text = "No Buses Found"
            }
            
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCellWithIdentifier("RouteStopCell", forIndexPath: indexPath) as! RouteStopTableViewCell
            let info = busArrivalInfo[indexPath.row]
            
            cell.titleLabel.text = info["name"]! as? String
            cell.timeRemainingLabel.text = formattedStringForArrivalTime(Int(info["eta"]! as! NSNumber))
            
            let lineType = RouteInformationManager.sharedInstance.busLineTypeForString(info["route_no"]! as! String)
            
            cell.lineLabel.setLineType(lineType)
            
            cell.lineLabel.widthConstraint.constant = lineLabelWidth
            cell.lineLabel.setNeedsUpdateConstraints()
            
            return cell
            
        }

    }

    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
            case ARRIVING_BUSES_SECTION:
                return "Buses approaching this stop"
            default:
                return nil
        }
    }
    
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let tappedIndexPath = tableView.indexPathForCell(sender! as! UITableViewCell)!
        let tappedTripID = busArrivalInfo[tappedIndexPath.row]["trip_id"] as! String
        
        print("tapped trip id = \(tappedTripID)")
        
        //find the route info before we actually segue
        
        let (lineName, routeName, lineType) = DatabaseManager.sharedInstance.infoForTripIdentifier(tappedTripID)
        
        let destination = segue.destinationViewController as! LineViewTableViewController
        destination.stopsOnRoute = DatabaseManager.sharedInstance.stopsOnRouteWithTripIdentifier(tappedTripID)
        
        destination.lineName = lineName
        destination.routeName = routeName
        destination.lineType = lineType
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        self.navigationItem.title = "Stop \(stopNumber)"
        
        if self.tableView.indexPathForSelectedRow != nil {
            self.tableView.deselectRowAtIndexPath(self.tableView.indexPathForSelectedRow!, animated: true)
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        stopInfoParser = StopInformationParser(stopNumber: stopNumber)
        stopInfoParser.delegate = self
        
        stopInfoParser.updateData()
        
        infoUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(UPDATE_FREQUENCY_SECONDS, target: stopInfoParser, selector: "updateData", userInfo: nil, repeats: true)
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        
        stopInfoParser = nil
        
        busArrivalInfo = []
        hasReceivedInfo = false
        routeThumbnailWidth = CGFloat(MIN_THUMBNAIL_WIDTH)
        
        infoUpdateTimer.invalidate()
        
    }

}
