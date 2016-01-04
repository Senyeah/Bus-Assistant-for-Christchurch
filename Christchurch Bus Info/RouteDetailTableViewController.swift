//
//  RouteDetailTableViewController.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 21/12/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

protocol RouteDetailSegmentInfoDelegate {
    func routeDetailController(controller: RouteDetailTableViewController, didSelectTripInfoSegment segmentOffset: Int)
    func routeDetailController(controller: RouteDetailTableViewController, didSelectInfoForStartStopOnSegment segmentOffset: Int)
    func routeDetailController(controller: RouteDetailTableViewController, didSelectInfoForEndStopOnSegment segmentOffset: Int)
}

class RouteDetailTableViewController: UITableViewController {
    
    var tripInfo: TripPlannerJourney!
    var delegate: RouteDetailSegmentInfoDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.contentInset = UIEdgeInsets(top: 14.0, left: 0.0, bottom: 14.0, right: 0.0)
    }
    
    func formattedTimeStringForDuration(duration: Int) -> String {
        
        let hours = Int(floor(Double(duration / 60)))
        var minutes = duration
        
        var returnString: String = ""
        
        if hours > 0 {
            minutes %= 60
            
            returnString = "\(hours) hour"
            
            if hours > 1 {
                returnString += "s"
            }
            
            returnString += " "
        }
        
        if minutes > 1 {
            returnString += "\(minutes) minutes"
        } else if minutes == 1 {
            returnString += "1 minute"
        }
        
        return returnString

    }
    
    @IBAction func detailsDoneButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let selectedSegmentOffset = Int(ceil((Double(indexPath.row) + 1.0) / 3.0)) - 1
        
        if (indexPath.row - 1) % 3 == 0 {
            //Transit Cell
            delegate?.routeDetailController(self, didSelectTripInfoSegment: selectedSegmentOffset)
        } else if (indexPath.row - 2) % 3 == 0 {
            //Segment End Info
            delegate?.routeDetailController(self, didSelectInfoForEndStopOnSegment: selectedSegmentOffset)
        } else {
            //Segment Start Info
            delegate?.routeDetailController(self, didSelectInfoForStartStopOnSegment: selectedSegmentOffset)
        }
        
        self.dismissViewControllerAnimated(true) {
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
        }
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let segmentOffset = Int(ceil((Double(indexPath.row) + 1.0) / 3.0)) - 1        
        let segment = tripInfo.segments[segmentOffset]
        
        if (indexPath.row - 1) % 3 == 0 {
            
            //Transit cell
            let cell = tableView.dequeueReusableCellWithIdentifier("JourneyTransitCell", forIndexPath: indexPath) as! JourneyTransitTableViewCell
            
            cell.tripStopIndicator.segmentType = .TransitSegment
            cell.isBusJourney = segment.isBusJourney
            
            if segment.isBusJourney {
                
                cell.lineInfoLabelLeadingConstraint.active = false
                cell.lineLabel.hidden = false
                
                cell.lineLabel.setLineType(segment.route!)
                cell.lineLabel.heightConstraint?.active = true
                
                let tripInfo = DatabaseManager.sharedInstance.infoForTripIdentifier(segment.tripID!)!
                cell.routeLabel.text = tripInfo.routeName
                
                let tripColours = tripInfo.lineType.colours()
                cell.tripStopIndicator.lineColour = tripColours.background
                
            } else {
                
                cell.routeLabel.text = "Walk"
                cell.tripStopIndicator.lineColour = nil

                cell.lineLabel.heightConstraint?.active = false
                
                cell.lineLabel.hidden = true
                cell.lineInfoLabelLeadingConstraint.active = true
                
            }
            
            cell.lineLabel.setNeedsLayout()
            
            cell.tripStopIndicator.segmentType = .TransitSegment
            cell.routeInfoLabel.text = formattedTimeStringForDuration(segment.duration)
            
            return cell
            
        } else {
            
            //Destination cell
            let cell = tableView.dequeueReusableCellWithIdentifier("JourneyStopCell", forIndexPath: indexPath) as! JourneyStopTableViewCell
            
            if segment.isBusJourney {
                let tripInfo = DatabaseManager.sharedInstance.infoForTripIdentifier(segment.tripID!)!
                let tripColours = tripInfo.lineType.colours()
                
                cell.stopIndicator.lineColour = tripColours.background
            } else {
                cell.stopIndicator.lineColour = nil
            }
                        
            //segment end
            if (indexPath.row - 2) % 3 == 0 {
                if segment.endStop != nil {
                    let info = RouteInformationManager.sharedInstance.stopInformation![segment.endStop!]!
                    cell.stopNameLabel.text = "\(info.name) (\(segment.endStop!))"
                } else {
                    cell.stopNameLabel.text = tripInfo.endLocationString ?? "Destination"
                }
                
                cell.timeLabel.text = segment.endTime.localisedTimeString
                cell.stopIndicator.segmentType = .EndSegment
            } else {
                if segment.startStop != nil {
                    let info = RouteInformationManager.sharedInstance.stopInformation![segment.startStop!]!
                    cell.stopNameLabel.text = "\(info.name) (\(segment.startStop!))"
                } else {
                    cell.stopNameLabel.text = tripInfo.startLocationString ?? "Start"
                }

                cell.timeLabel.text = segment.startTime.localisedTimeString
                cell.stopIndicator.segmentType = .StartSegment
            }

            return cell
            
        }
        
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3 * tripInfo.segments.count
    }
    
}
