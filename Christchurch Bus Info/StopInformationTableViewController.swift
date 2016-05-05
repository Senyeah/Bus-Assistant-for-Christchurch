//
//  StopInformationTableViewController.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 14/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit
import MapKit

class StopInformationTableViewController: UITableViewController, StopInformationParserDelegate {
    
    static let stopHeaderSection = 0
    static let arrivingBusesSection = 1
    static let routesPassingStopSection = 2
    
    static let updateFrequencySeconds = 15.0
    
    @IBOutlet var favouriteButton: UIBarButtonItem!
    @IBOutlet var headerMapView: MKMapView!
    
    var stopNumber: String!
    var stopInfoParser: StopInformationParser!
    
    var arrivingBusesLineLabelWidth: CGFloat = 0.0
    
    var hasReceivedInfo = false
    var infoUpdateTimer: NSTimer!
    
    var stopIsInFavourites = false {
        didSet {
            let favouriteStopNumbers = Preferences.favouriteStops.map { stop in
                return stop.stopNo
            }
            
            if stopIsInFavourites {
                favouriteButton.image = UIImage(named: "star-filled")
                
                if favouriteStopNumbers.contains(stopNumber) == false {
                    Preferences.favouriteStops.append(RouteInformationManager.sharedInstance.stopInformationForStopNumber(stopNumber)!)
                }
            } else {
                favouriteButton.image = UIImage(named: "star-hollow")
                
                if favouriteStopNumbers.contains(stopNumber) {
                    let indexToRemove = favouriteStopNumbers.indexOf(stopNumber)
                    Preferences.favouriteStops.removeAtIndex(indexToRemove!)
                }
            }
        }
    }
    
    var busArrivalInfo: [[String: AnyObject]] = [] {
        didSet {
            let prototypeLineLabelView = BusLineLabelView(lineType: BusLineType(lineAbbreviationString: ""))
            
            for item in busArrivalInfo {
                let lineType = BusLineType(lineAbbreviationString: item["route_no"]! as! String)
                prototypeLineLabelView.setLineType(lineType)
                
                arrivingBusesLineLabelWidth = max(arrivingBusesLineLabelWidth, prototypeLineLabelView.widthConstraint!.constant)
            }
        }
    }
    
    var tripsPassingStop: [TripInformation] = []
    
    lazy var routesPassingStopLineLabelWidth: CGFloat = { [unowned self] in
        
        var maximum: CGFloat = 0.0
        let prototypeLineLabelView = BusLineLabelView(lineType: BusLineType(lineAbbreviationString: ""))
        
        for trip in self.tripsPassingStop {
            prototypeLineLabelView.setLineType(trip.lineType)
            maximum = max(maximum, prototypeLineLabelView.widthConstraint!.constant)
        }
        
        return maximum
        
    }()
    
    @IBAction func favouriteButtonPressed() {
        stopIsInFavourites = !stopIsInFavourites
    }

    func stopInformationParser(parser: StopInformationParser, didReceiveStopInformation info: [[String: AnyObject]]) {
        
        //Weird things happen if you don't update the UI on the main thread
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.busArrivalInfo = info
            
            if self.hasReceivedInfo {
                UIView.performWithoutAnimation {
                    self.tableView.reloadSections(NSIndexSet(index: StopInformationTableViewController.arrivingBusesSection), withRowAnimation: .Automatic)
                }
            } else {
                self.hasReceivedInfo = true
                self.tableView.reloadSections(NSIndexSet(index: StopInformationTableViewController.arrivingBusesSection), withRowAnimation: .Automatic)
            }

        }
        
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return headerMapView.frame.height
        }
        
        return 35.0
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return headerMapView
        }
        
        return nil
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {

        if indexPath.section == StopInformationTableViewController.arrivingBusesSection {
            cell.layoutMargins = UIEdgeInsets(top: 0.0, left: arrivingBusesLineLabelWidth + 30.0, bottom: 0.0, right: 0.0)
        } else if indexPath.section == StopInformationTableViewController.routesPassingStopSection {
            cell.layoutMargins = UIEdgeInsets(top: 0.0, left: routesPassingStopLineLabelWidth + 30.0, bottom: 0.0, right: 0.0)
        }

    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == StopInformationTableViewController.stopHeaderSection {
            return 1
        } else if section == StopInformationTableViewController.arrivingBusesSection {
            return max(1, busArrivalInfo.count)
        } else {
            return tripsPassingStop.count
        }
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.section == StopInformationTableViewController.stopHeaderSection {
            
            let cell = tableView.dequeueReusableCellWithIdentifier("BusStopInfoCell", forIndexPath: indexPath) as! BusStopInfoTableViewCell
            
            cell.stopName.text = RouteInformationManager.sharedInstance.displayStringForStopNumber(stopNumber)
            cell.stopNumber.text = "Stop " + stopNumber
            
            return cell
            
        } else if indexPath.section == StopInformationTableViewController.arrivingBusesSection {
         
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
                cell.detailLabel.text = Int(info["eta"]! as! NSNumber).minuteDurationStringRepresentation(true)
                
                let lineType = BusLineType(lineAbbreviationString: info["route_no"]! as! String)
                
                cell.lineLabel.setLineType(lineType)
                
                cell.lineLabel.widthConstraint!.constant = arrivingBusesLineLabelWidth
                cell.lineLabel.setNeedsUpdateConstraints()
                
                cell.tripID = info["trip_id"]! as! String
                
                return cell
                
            }
            
        } else {
            
            let tripInformation = tripsPassingStop[indexPath.row]
            let cell = tableView.dequeueReusableCellWithIdentifier("RouteStopCell", forIndexPath: indexPath) as! RouteStopTableViewCell
            
            cell.titleLabel.text = tripInformation.lineName
            cell.detailLabel.text = "Towards " + tripInformation.routeName
            
            cell.lineLabel.setLineType(tripInformation.lineType)
            
            cell.lineLabel.widthConstraint!.constant = routesPassingStopLineLabelWidth
            cell.lineLabel.setNeedsUpdateConstraints()
            
            cell.tripID = tripInformation.tripID
            
            return cell
            
        }

    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
            case StopInformationTableViewController.arrivingBusesSection:
                return "Buses approaching this stop"
            case StopInformationTableViewController.routesPassingStopSection:
                return "Routes passing this stop"
            default:
                return nil
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == StopInformationTableViewController.stopHeaderSection {
            return 65.0
        }
        
        return 60.0
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let tappedCell = sender as! RouteStopTableViewCell
        
        //find the route info before we actually segue
        
        guard let tripInformation = DatabaseManager.sharedInstance.infoForTripIdentifier(tappedCell.tripID) else {
            return
        }
        
        let destination = segue.destinationViewController as! LineViewTableViewController
        
        guard let stopsOnRoute = DatabaseManager.sharedInstance.stopsOnRouteWithTripIdentifier(tappedCell.tripID) else {
            return
        }
        
        destination.stopsOnRoute = stopsOnRoute
        
        destination.lineName = tripInformation.lineName
        destination.routeName = tripInformation.routeName
        destination.lineType = tripInformation.lineType
        destination.tripID = tappedCell.tripID
        
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation.isKindOfClass(BusStopAnnotation) {
            return MKPinAnnotationView(annotation: annotation, reuseIdentifier: "BusStopLocationPin")
        }
        
        return nil
        
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            let tripsThroughStop = DatabaseManager.sharedInstance.routesPassingStop(self.stopNumber) ?? []
            
            let indexPaths = tripsThroughStop.indices.map { index in
                return NSIndexPath(forRow: index, inSection: StopInformationTableViewController.routesPassingStopSection)
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                
                self.tableView.beginUpdates()
                
                self.tripsPassingStop = tripsThroughStop
                self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
                
                self.tableView.endUpdates()
                
            }
            
        }
                
        let stopInfo = RouteInformationManager.sharedInstance.stopInformation![stopNumber]!
        let stopAnnotation = BusStopAnnotation(stop: stopInfo)
        
        self.navigationItem.title = "Stop \(stopNumber)"
        
        headerMapView.addAnnotation(stopAnnotation)
        
        let coordinateRegion = MKCoordinateRegionMake(stopInfo.location.coordinate, MKCoordinateSpanMake(0.005, 0.005))
        headerMapView.setRegion(coordinateRegion, animated: false)
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if self.tableView.indexPathForSelectedRow != nil {
            self.tableView.deselectRowAtIndexPath(self.tableView.indexPathForSelectedRow!, animated: true)
        }
        
        stopInfoParser = StopInformationParser(stopNumber: stopNumber)
        stopInfoParser.delegate = self
        
        stopInfoParser.updateData()
        
        infoUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(StopInformationTableViewController.updateFrequencySeconds,
                                                                 target: stopInfoParser, selector: #selector(StopInformationParser.updateData),
                                                                 userInfo: nil, repeats: true)
        
        let favouriteStopNumbers = Preferences.favouriteStops.map { stop in
            return stop.stopNo
        }
        
        stopIsInFavourites = favouriteStopNumbers.contains(stopNumber)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        
        stopInfoParser = nil
        
        busArrivalInfo = []
        hasReceivedInfo = false
        
        arrivingBusesLineLabelWidth = CGFloat(0.0)
        
        infoUpdateTimer.invalidate()
        
    }

}
