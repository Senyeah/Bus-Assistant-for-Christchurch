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
    
    var hasReceivedInfo = false
    var busArrivalInfo = [[String: AnyObject]]()
    
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
    
    
//    func busLineLabelViewDidDetermineIntrinsicContentWidth(width: CGFloat, forView view: BusLineLabelView, withWidthConstraint constraint: NSLayoutConstraint) {
//        
//        struct StaticInstance {
//            static var timesCalled = 0
//            static var viewWidths = [CGFloat]()
//            static var constraints = [NSLayoutConstraint]()
//        }
//        
//        StaticInstance.viewWidths.append(width)
//        StaticInstance.constraints.append(constraint)
//        
//        StaticInstance.timesCalled++
//        
//        if StaticInstance.timesCalled == busArrivalInfo.count {
//            
//            //Determine whether the widths are all the same
//            
//            let uniqueWidths = Set(StaticInstance.viewWidths)
//            
//            if uniqueWidths.count > 1 {
//                
//                routeThumbnailWidth = uniqueWidths.maxElement()!
//                let changeInWidth = routeThumbnailWidth - CGFloat(MIN_THUMBNAIL_WIDTH)
//                
//                separatorInset = CGFloat(DEFAULT_SEPARATOR_INSET) + changeInWidth
//                
//                for index in 0..<StaticInstance.constraints.count {
//                    StaticInstance.constraints[index].constant = routeThumbnailWidth
//                 //   print("setting item \(index) of \(StaticInstance.constraints.count-1) to \(routeThumbnailWidth)")
//                }
//                
//                dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                    view.setNeedsUpdateConstraints()
//                })
//                
//            }
//            
//            StaticInstance.timesCalled = 0
//            StaticInstance.viewWidths = []
//            StaticInstance.constraints = []
//            
//        }
//    }
    
    
    func stopInformationParser(parser: StopInformationParser, didReceiveStopInformation info: [[String : AnyObject]]) {
        
        //Weird things happen if you don't update the UI on the main thread
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.busArrivalInfo = info
            self.hasReceivedInfo = true
            
            self.tableView.reloadData()
            
        })
        
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("RouteStopCell", forIndexPath: indexPath) as! RouteStopTableViewCell
        cell.layoutMargins = UIEdgeInsets(top: 0.0, left: cell.titleLabel.frame.origin.x + 150.0, bottom: 0.0, right: 0.0)
            
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
            let info: [String: AnyObject] = busArrivalInfo[indexPath.row]
            
            cell.titleLabel.text = info["name"]! as? String
            cell.timeRemainingLabel.text = formattedStringForArrivalTime(Int(info["eta"]! as! NSNumber))
            
            let lineType = RouteInformationManager.sharedInstance.busLineTypeForString(info["route_no"]! as! String)
            
            cell.lineLabel.setLineType(lineType)
            
            cell.lineLabel.widthConstraint.constant = max(cell.lineLabel.widthConstraint.constant, routeThumbnailWidth)
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
    
    
    override func viewDidDisappear(animated: Bool) {
        
        stopInfoParser = nil
        
        busArrivalInfo = []
        hasReceivedInfo = false
        routeThumbnailWidth = CGFloat(MIN_THUMBNAIL_WIDTH)
        
        infoUpdateTimer.invalidate()
        
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
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


}
