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
    
    var majorStopsOnRoute: [StopOnRoute] = []
    var numberOfStopsInIntermediateSection: [Int] = []
    
    var majorStopIndices: [Int] = []
    var intermediateSectionIndices: [Int] = []
    
    var stopsOnRoute: [StopOnRoute] = [] {
        didSet {
            var count = 0
            var index = 0
            
            for stop in stopsOnRoute {
                if stop.isMajorStop {

                    if count > 0 {
                        intermediateSectionIndices.append(majorStopsOnRoute.count + intermediateSectionIndices.count)
                        numberOfStopsInIntermediateSection.append(count)
                        count = 0
                    }
                    
                    majorStopIndices.append(majorStopsOnRoute.count + intermediateSectionIndices.count)
                    majorStopsOnRoute.append(stop)
                    
                } else {
                    count += 1
                }
                
                index += 1
            }            
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
            return majorStopsOnRoute.count + numberOfStopsInIntermediateSection.count
        }
    }
    
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
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
            
            let isIntermediate = intermediateSectionIndices.contains(indexPath.row)
            
            if isIntermediate == false {
                
                let cell = tableView.dequeueReusableCellWithIdentifier("LineMajorStopCell", forIndexPath: indexPath) as! LineMajorStopTableViewCell
                let stopInfo = majorStopsOnRoute[majorStopIndices.indexOf(indexPath.row)!]
                
                
                cell.titleLabel.text = stopInfo.stopName
                
                cell.lineStopIndicator.isMajorStop = true
                cell.lineStopIndicator.strokeColour = lineColour
                
                cell.separatorInset = UIEdgeInsets(top: 0.0, left: cell.contentView.frame.width, bottom: 0.0, right: 0.0)
                
                if indexPath.row == 0 {
                    cell.lineStopIndicator.stopType = .LineStart
                } else if indexPath.row == tableView.numberOfRowsInSection(indexPath.section) - 1 {
                    cell.lineStopIndicator.stopType = .LineEnd
                } else {
                    cell.lineStopIndicator.stopType = .IntermediateStop
                }
                
                
                return cell
                
            } else {
                
                let cell = tableView.dequeueReusableCellWithIdentifier("LineMinorStopCell", forIndexPath: indexPath) as! LineMinorStopTableViewCell
                let numberOfStopsInSection = numberOfStopsInIntermediateSection[intermediateSectionIndices.indexOf(indexPath.row)!]
                
                cell.titleLabel.text = "\(numberOfStopsInSection) stop" + ((numberOfStopsInSection > 1) ? "s" : "")
                
                cell.lineStopIndicator.isMajorStop = false
                cell.lineStopIndicator.strokeColour = lineColour
                
                cell.separatorInset = UIEdgeInsets(top: 0.0, left: cell.contentView.frame.width, bottom: 0.0, right: 0.0)
                cell.lineStopIndicator.stopType = .IntermediateStop
                                
                return cell
                
            }
            
        }
        
        //cell.separatorInset = UIEdgeInsets(top: 0.0, left: cell.contentView.frame.width, bottom: 0.0, right: 0.0)
        
        
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
