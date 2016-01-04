//
//  RoutePlannerViewController.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 12/12/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit
import CoreLocation

class RouteOptionsDataSource: NSObject, UITableViewDelegate, UITableViewDataSource, PlaceSearchResultDelegate {
    
    var rowAffected: Int = 0
    var routePlannerController: RoutePlannerViewController?
    
    var optionsTableView: UITableView?
    
    func locationWasChosenWithName(name: String, coordinate: CLLocationCoordinate2D) {
        
        if rowAffected == 0 {
            routePlannerController?.startCoordinate = coordinate
            routePlannerController?.startLabel = name
        } else if rowAffected == 1 {
            routePlannerController?.finishCoordinate = coordinate
            routePlannerController?.finishLabel = name
        }
        
        optionsTableView?.reloadData()
        routePlannerController?.checkForValidJourney()
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if optionsTableView == nil {
            optionsTableView = tableView
        }
        
        if indexPath.row < 2 {
            
            let cell = tableView.dequeueReusableCellWithIdentifier("RouteOptionsCell", forIndexPath: indexPath)
            
            if indexPath.row == 0 {
                cell.detailTextLabel?.text = routePlannerController?.startLabel ?? "Choose…"
            } else {
                cell.textLabel?.text = "End"
                cell.detailTextLabel?.text = routePlannerController?.finishLabel ?? "Choose…"
            }
            
            cell.layoutMargins = UIEdgeInsetsZero
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCellWithIdentifier("RouteTimePickerCell", forIndexPath: indexPath)
            
            cell.textLabel?.text = "Depart After"
            cell.detailTextLabel?.text = routePlannerController?.startTime.toShortDateTimeString()
            
            cell.layoutMargins = UIEdgeInsetsZero
            return cell
            
        }
        
    }
    
}

class RoutePlannerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TripPlannerDelegate, DatePickerDelegate {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var routeOptionsTableView: UITableView!
    
    var startCoordinate: CLLocationCoordinate2D?
    var finishCoordinate: CLLocationCoordinate2D?
    
    var startLabel: String?
    var finishLabel: String?
    
    var startTime = NSDate()
    
    var trip: TripPlanner?
    var trips: [TripPlannerJourney] = [] {
        didSet {
            for index in 0..<trips.count {
                trips[index].startLocationString = startLabel
                trips[index].endLocationString = finishLabel
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func datePickerDidSelectNewDate(date: NSDate) {
        startTime = date
        routeOptionsTableView.reloadData()
        
        checkForValidJourney()
    }
    
    func checkForValidJourney() {
        
        if startCoordinate != nil && finishCoordinate != nil {
            
            trips = []
            tableView.reloadData()
            
            let loadingIndicator = TableViewLoadingBackgroundView.initView()
            tableView.backgroundView = loadingIndicator
            
            //Plan the trip
            trip = TripPlanner(start: CLLocation(latitude: startCoordinate!.latitude, longitude: startCoordinate!.longitude),
                               end: CLLocation(latitude: finishCoordinate!.latitude, longitude: finishCoordinate!.longitude),
                               time: startTime, updateDelegate: self)
            
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let sendingTableView = (sender as! UITableViewCell).superview?.superview as! UITableView
        
        if sendingTableView == routeOptionsTableView && sendingTableView.indexPathForSelectedRow!.row < 2 {
            
            let modalLocationPicker = (segue.destinationViewController as! UINavigationController).viewControllers.first as! PlaceSearchViewController
            var routeOptionsDataSource = routeOptionsTableView.delegate! as! PlaceSearchResultDelegate
            
            routeOptionsDataSource.rowAffected = routeOptionsTableView.indexPathForSelectedRow!.row
            modalLocationPicker.delegate = routeOptionsDataSource
            
        } else if sendingTableView == routeOptionsTableView && sendingTableView.indexPathForSelectedRow!.row == 2 {
            
            let dateTimePicker = (segue.destinationViewController as! UINavigationController).viewControllers.first as! DatePickerViewController
            
            dateTimePicker.selectedDate = startTime
            dateTimePicker.delegate = self
            
        } else {
            
            let routeOverviewController = segue.destinationViewController as! RouteOverviewViewController
            routeOverviewController.tripInfo = trips[sendingTableView.indexPathForSelectedRow!.row]
            
        }
    }
    
    func formattedDuration(minutes: Int) -> String {
        
        let hoursAway = Int(floor(Double(minutes / 60)))
        var minutesAway = minutes
        
        var returnString: String = ""
        
        if hoursAway > 0 {
            minutesAway %= 60
            returnString = "\(hoursAway)h "
        }
        
        returnString += "\(minutesAway)m"
        
        return returnString
        
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        var routeOptionsDataSource = routeOptionsTableView.delegate! as! PlaceSearchResultDelegate
        routeOptionsDataSource.routePlannerController = self

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if TripPlanner.canAccessServer() == false {
                dispatch_sync(dispatch_get_main_queue()) {
                    self.tripPlannerDidCompleteWithError(nil, error: .ConnectionError)
                }
            }
        }
        
    }

    override func viewWillAppear(animated: Bool) {
        if routeOptionsTableView.indexPathForSelectedRow != nil {
            routeOptionsTableView.deselectRowAtIndexPath(routeOptionsTableView.indexPathForSelectedRow!, animated: true)
        }
        
        if tableView.indexPathForSelectedRow != nil {
            tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow!, animated: true)
        }
    }
    
    func tripPlannerDidBegin(planner: TripPlanner) {
        print("trip planner began!")
    }
    
    func tripPlannerDidCompleteWithError(planner: TripPlanner?, error: TripPlannerError) {
        var errorTitle: String
        var errorMessage: String
        
        switch error {
        case .ConnectionError:
            errorTitle = "Connection Error"
            errorMessage = "The route planner service could not be accessed. Check that you have a connection to the Internet."
        case .ParseError:
            errorTitle = "Unavailable"
            errorMessage = "The route planner service is temporarily unavailable."
        case .VersionError:
            errorTitle = "Outdated Database"
            errorMessage = "The database needs to be updated before this journey can be planned."
        }
        
        tableView.backgroundView = TableViewErrorBackgroundView.initView(errorTitle, errorDetail: errorMessage)
    }
    
    func tripPlannerDidCompleteSuccessfully(planner: TripPlanner, journey: [TripPlannerJourney]) {
        if journey.count == 0 {
            tableView.backgroundView = TableViewErrorBackgroundView.initView("No Trips Found", errorDetail: "No trips could be found which match the specified criteria.")
        } else {
            tableView.backgroundView = nil
        }
        
        trips = journey.sort {
            return $0.0.finishTime < $0.1.finishTime
        }
        
        tableView.reloadData()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trips.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("RouteOptionCell", forIndexPath: indexPath) as! RouteOptionTableViewCell
        let trip = trips[indexPath.row]
        
        let (_, startTime) = trip.startTime.toDateTimeString(true)
        let (_, endTime) = trip.finishTime.toDateTimeString(true)
        
        cell.timeLabel.text = startTime + " – " + endTime
        cell.durationLabel.text = formattedDuration(trip.duration)
        
        cell.transitTimeLabel.text = formattedDuration(trip.transitTime)
        cell.walkTimeLabel.text = formattedDuration(trip.walkTime)
        
        cell.routes = trip.routes
        
        cell.layoutMargins = UIEdgeInsetsZero
        return cell
        
    }

}
