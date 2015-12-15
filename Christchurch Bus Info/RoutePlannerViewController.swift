//
//  RoutePlannerViewController.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 12/12/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

class RouteOptionsDataSource: NSObject, UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("RouteOptionsCell", forIndexPath: indexPath)
        
        if indexPath.row == 0 {
            cell.detailTextLabel?.text = "Evans Pass Road, Sumner"
        } else if indexPath.row == 1 {
            cell.textLabel?.text = "End"
            cell.detailTextLabel?.text = "25 Gardiners Road, Bishopdale"
        } else if indexPath.row == 2 {
            cell.textLabel?.text = "Depart After"
            cell.detailTextLabel?.text = "1:30 PM"

        }
        
        cell.layoutMargins = UIEdgeInsetsZero
        return cell
    }
    
}

class RoutePlannerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TripPlannerDelegate {

    @IBOutlet var tableView: UITableView!
    
    var trip: TripPlanner?
    var trips: [TripPlannerJourney] = []
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
        
        let startID = RouteInformationManager.sharedInstance.stopInformationForStopNumber("19416")?.location
        let finishID = RouteInformationManager.sharedInstance.stopInformationForStopNumber("37404")?.location
        
        trip = TripPlanner(start: startID!, end: finishID!, time: NSDate.representationToDate("2015-12-25 10:30:00"), updateDelegate: self)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tripPlannerDidBegin(planner: TripPlanner) {
        print("trip planner began!")
    }
    
    func tripPlannerDidCompleteWithError(planner: TripPlanner, error: TripPlannerError) {
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
