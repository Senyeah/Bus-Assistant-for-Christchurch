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
    
    private var selectedRoutes: [BusLineType] {
        get {
            //future me: using map is impossible here, good luck is all I say if you try
            var items: [BusLineType] = []
            
            for (_, routes) in lineSections {
                for (route, isChecked) in routes {
                    if isChecked {
                        items.append(route.lineType)
                    }
                }
            }
            
            return items
        }
    }
    
    private var lineSections: LineSectionInformation = [] {
        didSet {
            Preferences.mapRoutes = selectedRoutes
        }
    }
    
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
        
        //Set the line section information to values saved
        
        var defaultValues: LineSectionInformation = [(sectionTitle: "Metro Lines", routes: []),
                                                     (sectionTitle: "City Connectors", routes: []),
                                                     (sectionTitle: "Suburban Links", routes: [])]
        
        for (lineType, routeName) in allRoutes {
            let routeIsSaved = delegate!.selectedRoutes().contains(lineType)
            
            switch lineType {
            case .Orbiter(let direction):
                if direction == .AntiClockwise {
                    continue
                } else {
                    fallthrough
                }
            case .PurpleLine, .OrangeLine, .BlueLine, .YellowLine:
                defaultValues[0].routes.append((route: (lineType: lineType, routeName: routeName), isChecked: routeIsSaved))
                continue
            default:
                break
            }
            
            let index = lineType.toString.characters.count == 2 ? 1 : 2
            defaultValues[index].routes.append((route: (lineType: lineType, routeName: routeName), isChecked: routeIsSaved))
        }
        
        lineSections = defaultValues
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.delegate?.selectedRoutesDidChange(selectedRoutes)
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
        let (routeInfo, isChecked) = lineSections[indexPath.section].routes[indexPath.row]
        
        cell.lineLabelView.setLineType(routeInfo.lineType)
        cell.lineNameLabel.text = routeInfo.routeName
        
        //hack to display only one orbiter
        
        switch routeInfo.lineType {
            case .Orbiter(_):
                cell.lineLabelView.label.text = "Or"
            default:
                break
        }
        
        cell.lineLabelView.widthConstraint!.constant = lineLabelWidth
        cell.accessoryType = isChecked ? .Checkmark : .None
        
        return cell
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let selectedCell = tableView.cellForRowAtIndexPath(indexPath) as! LineFilterTableViewCell
        let (_, isChecked) = lineSections[indexPath.section].routes[indexPath.row]
        
        if isChecked {
            selectedCell.accessoryType = .None
        } else {
            selectedCell.accessoryType = .Checkmark
        }
        
        lineSections[indexPath.section].routes[indexPath.row].isChecked = !isChecked
        
    }

}
