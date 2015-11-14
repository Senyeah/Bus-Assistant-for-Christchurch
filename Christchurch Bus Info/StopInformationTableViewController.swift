//
//  StopInformationTableViewController.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 14/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

let UPDATE_FREQUENCY_SECONDS = 30.0

class StopInformationTableViewController: UITableViewController, StopInformationParserDelegate {
    
    var stopNumber: String!
    
    var stopInfoParser: StopInformationParser!
    
    var hasReceivedInfo = false
    var busArrivalInfo = [[String: AnyObject]]()
    
    var infoUpdateTimer: NSTimer!
    
    
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
        
        self.navigationItem.title = "Stop \(stopNumber)"
        
        stopInfoParser = StopInformationParser(stopNumber: stopNumber)
        stopInfoParser.delegate = self
        
        stopInfoParser.updateData()
        
        infoUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(UPDATE_FREQUENCY_SECONDS, target: stopInfoParser, selector: "updateData", userInfo: nil, repeats: true)
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func stopInformationParser(parser: StopInformationParser, didReceiveStopInformation info: [[String : AnyObject]]) {
        
        //Weird things happen if you don't update the UI on the main thread
        
        dispatch_sync(dispatch_get_main_queue(), { () -> Void in
            
            self.busArrivalInfo = info
            self.hasReceivedInfo = true
            
            self.tableView.reloadData()
            
        })
        
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
            
            return cell
            
        }

    }

    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
            case 0:
                return "Buses arriving at this stop"
            default:
                return nil
        }
    }
    
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        
        stopNumber = nil
        busArrivalInfo = [[String: AnyObject]]()
        hasReceivedInfo = false
        
        infoUpdateTimer.invalidate()
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
