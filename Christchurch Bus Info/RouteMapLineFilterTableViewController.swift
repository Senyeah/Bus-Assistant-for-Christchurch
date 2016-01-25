//
//  RouteMapLineFilterTableViewController.swift
//  Bus Assistant
//
//  Created by Jack Greenhill on 20/01/16.
//  Copyright © 2016 Miyazu App + Web Design. All rights reserved.
//

import UIKit

protocol RouteMapFilterUpdateDelegate {
    func selectedRoutesDidChange(routes: [BusLineType])
    func selectedRoutes() -> [BusLineType]
}

class LineFilterTableViewCell: UITableViewCell {
    @IBOutlet var lineLabelView: BusLineLabelView!
    @IBOutlet var lineNameLabel: UILabel!
}

class RouteMapLineFilterTableViewController: UITableViewController {
    
    var lineLabelWidth: CGFloat = CGFloat(0.0)
    var delegate: RouteMapFilterUpdateDelegate?
    
    private lazy var lineSections: LineSectionInformation = { [unowned self] in
        
        var result: LineSectionInformation = [(sectionTitle: "Metro Lines", routes: []),
                                              (sectionTitle: "City Connectors", routes: []),
                                              (sectionTitle: "Suburban Links", routes: [])]
        
        for (lineType, routeName) in DatabaseManager.sharedInstance.allRoutes! {
            switch lineType {
                case .Orbiter(let direction):
                    if direction == .AntiClockwise {
                        continue
                    } else {
                        fallthrough
                    }
                case .PurpleLine, .OrangeLine, .BlueLine, .YellowLine:
                    result[0].routes.append(lineType: lineType, routeName: routeName)
                    continue
                default:
                    break
            }
            
            //Two digit lines are city connectors
            
            let index = lineType.toString.characters.count == 2 ? 1 : 2
            result[index].routes.append(lineType: lineType, routeName: routeName)
        }
        
        return result
        
    }()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        guard let allRoutes = DatabaseManager.sharedInstance.allRoutes else {
            fatalError("Couldn't get the routes from the database!")
        }
        
        let prototypeLabelView = BusLineLabelView(lineType: BusLineType(lineAbbreviationString: ""))
        
        for (lineType, _) in allRoutes {
            prototypeLabelView.setLineType(lineType)
            lineLabelWidth = max(lineLabelWidth, prototypeLabelView.widthConstraint!.constant)
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.layoutMargins = UIEdgeInsets(top: 0.0, left: lineLabelWidth + 30.0, bottom: 0.0, right: 0.0)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return lineSections[section].sectionTitle
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return lineSections.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lineSections[section].routes.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("LineFilterCell", forIndexPath: indexPath) as! LineFilterTableViewCell
        let (lineType, routeName) = lineSections[indexPath.section].routes[indexPath.row]
        
        cell.lineLabelView.setLineType(lineType)
        cell.lineNameLabel.text = routeName
        
        //hack to display only one orbiter
        
        switch lineType {
            case .Orbiter(_):
                cell.lineLabelView.label.text = "Or"
            default:
                break
        }
        
        cell.lineLabelView.widthConstraint!.constant = lineLabelWidth

        let selectedRoutesStringRepresentation = delegate!.selectedRoutes().map { current in
            return current.toString
        }
        
        if selectedRoutesStringRepresentation.contains(lineType.toString) {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        
        return cell
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let selectedCell = tableView.cellForRowAtIndexPath(indexPath) as! LineFilterTableViewCell
        let (lineType, _) = lineSections[indexPath.section].routes[indexPath.row]
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            var selectedRoutesStringRepresentation = self.delegate!.selectedRoutes().map { current in
                return current.toString
            }
            
            if selectedRoutesStringRepresentation.contains(lineType.toString) {
                
                selectedCell.accessoryType = .None
                
                let index = selectedRoutesStringRepresentation.indexOf(lineType.toString)!
                selectedRoutesStringRepresentation.removeAtIndex(index)
                
            } else {
                selectedCell.accessoryType = .Checkmark
                selectedRoutesStringRepresentation.append(lineType.toString)
            }
            
            let selectedRoutes = selectedRoutesStringRepresentation.map { current in
                return BusLineType(lineAbbreviationString: current)
            }
            
            self.delegate?.selectedRoutesDidChange(selectedRoutes)
            
        }
        
    }

}
