//
//  LineViewTableViewController.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 14/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

class LineViewTableViewController: UITableViewController {
    
    var lineName: String!
    var routeName: String!
    var tripID: String!
    
    var lineColour: UIColor!
    
    var lineType: BusLineType = .NumberedRoute("error") {
        didSet {
            switch lineType {
            case .PurpleLine:
                lineColour = purple
            case .OrangeLine:
                lineColour = orange
            case .BlueLine:
                lineColour = blue
            case .YellowLine:
                lineColour = yellow
            case .Orbiter(_):
                lineColour = green
            case .NumberedRoute(_):
                lineColour = self.tableView.tintColor
            }
        }
    }
    
    var stopsToShow: [Int: StopOnRoute] = [:]
    var stopsToHide: [Int: Int] = [:]
    
    var intermediateSectionCount = 0
    
    var stopsOnRoute: [StopOnRoute] = [] {
        didSet {
            stopsToShow.removeAll()
            stopsToHide.removeAll()
            
            intermediateSectionCount = 0
            
            //make sure the first and last items are always shown
            
            stopsOnRoute[0].shouldDisplay = true
            stopsOnRoute[stopsOnRoute.count - 1].shouldDisplay = true
            
            var intermediateRowCount = 0
            var rowsInSectionCount = 0
            
            var row = 0
            var didShowLastRow = false
            
            for stop in stopsOnRoute {
                
                var wouldCollapseOnlyOneStop = false
                
                if stop.shouldDisplay == false && rowsInSectionCount == 0 {
                    if row == stopsOnRoute.count - 1 {
                        wouldCollapseOnlyOneStop = true
                    } else {
                        wouldCollapseOnlyOneStop = stopsOnRoute[row + 1].shouldDisplay
                    }
                }
                
                if stop.shouldDisplay || wouldCollapseOnlyOneStop {
                    
                    let index = row - intermediateRowCount + intermediateSectionCount
                    stopsToShow[index] = stop
                    
                    if didShowLastRow == false && intermediateRowCount > 0 {
                        stopsToHide[stopsToShow.count + intermediateSectionCount - 2] = rowsInSectionCount
                        rowsInSectionCount = 0
                    }
                    
                    didShowLastRow = true
                    
                } else {
                    
                    if didShowLastRow {
                        intermediateSectionCount += 1
                        didShowLastRow = false
                    }
                    
                    intermediateRowCount += 1
                    rowsInSectionCount += 1
                    
                }
                
                row += 1
                
            }
        }
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            
            let cell = tableView.dequeueReusableCellWithIdentifier("LineViewHeaderCell", forIndexPath: indexPath) as! LineViewHeaderTableViewCell
            
            cell.lineNameLabel.text = lineName
            cell.routeNameLabel.text = "Towards \(routeName)"
            
            cell.lineLabel.setLineType(lineType)
            
            return cell
            
        } else if indexPath.section == 1 {
        
            let cell = tableView.dequeueReusableCellWithIdentifier("BasicDetailCell", forIndexPath: indexPath)
            
            if indexPath.row == 0 {
                cell.textLabel?.text = "Route Map"
            } else {
                cell.textLabel?.text = "Other Routes On This Line"
            }
                        
            return cell
            
        } else {
            
            var cell: LineStopTableViewCell!
            
            if stopsToShow.keys.contains(indexPath.row) {
                
                let stopInfo = stopsToShow[indexPath.row]!
                
                if stopInfo.isIntermediate == false {
                    cell = tableView.dequeueReusableCellWithIdentifier("LineMajorStopCell", forIndexPath: indexPath) as! LineMajorStopTableViewCell
                } else {
                    cell = tableView.dequeueReusableCellWithIdentifier("LineMinorStopCell", forIndexPath: indexPath) as! LineMinorStopTableViewCell
                }
                
                cell.titleLabel.text = (stopInfo.isIntermediate ? "Near " : "") + stopInfo.stopName
                cell.lineStopIndicator.isMajorStop = !stopInfo.isIntermediate
                
                if indexPath.row == 0 {
                    cell.lineStopIndicator.stopType = .LineStart
                } else if indexPath.row == tableView.numberOfRowsInSection(indexPath.section) - 1 {
                    cell.lineStopIndicator.stopType = .LineEnd
                } else {
                    cell.lineStopIndicator.stopType = .IntermediateStop
                }
                
            } else {
                
                cell = tableView.dequeueReusableCellWithIdentifier("LineMinorStopCell", forIndexPath: indexPath) as! LineMinorStopTableViewCell
                
                guard let numberOfStopsInSection = stopsToHide[indexPath.row] else {
                    return cell
                }
                
                cell.titleLabel.text = "\(numberOfStopsInSection) stops"
                
                cell.lineStopIndicator.isMajorStop = false
                cell.lineStopIndicator.stopType = .IntermediateStop
                
            }
            
            cell.lineStopIndicator.strokeColour = lineColour
            cell.separatorInset = UIEdgeInsets(top: 0.0, left: cell.contentView.frame.width, bottom: 0.0, right: 0.0)
            
            return cell
            
        }
    }

    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 2 && stopsToShow.keys.contains(indexPath.row) == false {
            
            //we need to expand this collapsed section of stops
            
            let collapsedIntermediateStopsCount = stopsToHide.reduce(0) { (currentCollapsed, object) in
                let (key, numCollapsed) = object
                return (key < indexPath.row) ? currentCollapsed + numCollapsed : currentCollapsed
            }

            let stopsDisplayedAboveCollapseCount = stopsToShow.reduce(0) { (currentStopsDisplayed, object) in
                let (key, _) = object
                return (key < indexPath.row) ? currentStopsDisplayed + 1 : currentStopsDisplayed
            }
            
            let stopsCollapsedCount = stopsToHide[indexPath.row]
            let startIndex = stopsDisplayedAboveCollapseCount + collapsedIntermediateStopsCount
            
            var clone = stopsOnRoute
            var insertedRowsIndexPaths: [NSIndexPath] = []
            
            for index in startIndex..<startIndex + stopsCollapsedCount! {
                let newRowIndex = index - startIndex + indexPath.row
                insertedRowsIndexPaths.append(NSIndexPath(forRow: newRowIndex, inSection: indexPath.section))
                
                clone[index].shouldDisplay = true
                clone[index].isIntermediate = true
            }
            
            stopsOnRoute = clone
            
            tableView.beginUpdates()
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .None)
            tableView.insertRowsAtIndexPaths(insertedRowsIndexPaths, withRowAnimation: .Top)
            
            tableView.endUpdates()
            
        } else if indexPath.section == 2 && stopsToShow.keys.contains(indexPath.row) {
            
            self.performSegueWithIdentifier("LineStopInfoSegue", sender: tableView.cellForRowAtIndexPath(indexPath))
            
        } else if indexPath.section == 1 && indexPath.row == 0 {
            
            self.performSegueWithIdentifier("RouteMapViewSegue", sender: tableView.cellForRowAtIndexPath(indexPath))
            
        }
        
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let selectedRowIndexPath = tableView.indexPathForCell(sender as! UITableViewCell)!
        
        if selectedRowIndexPath.section == 1 {
        
            let mapViewController = segue.destinationViewController as! RouteMapViewController
            
            guard let coordinates = DatabaseManager.sharedInstance.routeCoordinatesForTripIdentifier(tripID) else {
                return
            }
            
            mapViewController.polylineCoordinates = coordinates
            
        } else if selectedRowIndexPath.section == 2 {
            
            let stopInfoViewController = segue.destinationViewController as! StopInformationTableViewController
            let stopInfo = stopsToShow[selectedRowIndexPath.row]!
            
            stopInfoViewController.stopNumber = stopInfo.stopNumber
            
        }
        
    }
    
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        return false
    }
    
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return 2
        } else {
            return stopsToShow.count + intermediateSectionCount
        }
    }
    
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
