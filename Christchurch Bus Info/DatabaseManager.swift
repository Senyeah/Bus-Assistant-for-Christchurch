//
//  DatabaseManager.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 15/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit
import SQLite
import CoreLocation

struct StopOnRoute {
    var stopName: String
    var stopNumber: String
    var shouldDisplay: Bool
    var isIntermediate: Bool = false
}

protocol DatabaseManagerDelegate {
    func databaseManagerDidParseDatabase(manager: DatabaseManager, database: [String: StopInformation])
}

let APPLICATION_SUPPORT_DIRECTORY = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true).last!

class DatabaseManager: NSObject {

    static let sharedInstance = DatabaseManager()
    static let databasePath = APPLICATION_SUPPORT_DIRECTORY + "/database.sqlite3"
    
    private var routesPassingStopQuery: String
    private var stopsForTripQuery: String
    private var timetabledTripsForStopQuery: String
    
    private var stopUpdateURLs: [String: NSURL] = [:]
    
    var delegate: DatabaseManagerDelegate?
    
    var database: Connection?
    var isConnected = false
    
    lazy var allRoutes: [RouteInformation]? = { [unowned self] in
        
        if self.isConnected == false {
            return nil
        }
        
        let results = try! self.database?.prepare("SELECT route_id, route_long_name FROM routes")
        
        return results!.map { row in
            let routeNumber = row[0] as! String
            let routeName = row[1] as! String
            
            return (lineType: BusLineType(lineAbbreviationString: routeNumber), routeName: routeName)
        }
        
    }()
    
    lazy var allStops: [[String]]? = { [unowned self] in
        
        if self.isConnected == false {
            return nil
        }
        
        guard let statement = try! self.database?.prepare("SELECT * FROM stops") else {
            return nil
        }

        return statement.map { row in
            return row.map { column in
                return column as! String? ?? ""
            }
        }
        
    }()
    
    func parseDatabase(runQueue: dispatch_queue_t = dispatch_get_main_queue()) {
        
        if isConnected == false {
            return
        }
        
        let parseBlock: () -> Void = {
            
            guard let stops = self.allStops else {
                return
            }
            
            let stopAttributes = ["stop_id", "stop_code", "stop_name", "stop_lat", "stop_lon", "stop_url", "road_name"]
            var stopInformation: [String: StopInformation] = [:]
            
            for stop in stops {
                
                let latitude = CLLocationDegrees(stop[stopAttributes.indexOf("stop_lat")!])!
                let longitude = CLLocationDegrees(stop[stopAttributes.indexOf("stop_lon")!])!
                
                let location = CLLocation(latitude: latitude, longitude: longitude)
                
                let stopNo = stop[stopAttributes.indexOf("stop_code")!]
                let stopTag = stop[stopAttributes.indexOf("stop_id")!]
                let stopName = stop[stopAttributes.indexOf("stop_name")!]
                
                //Figure out the road name
                let roadName = stop[stopAttributes.indexOf("road_name")!]
                
                stopInformation[stopNo] = StopInformation(stopNo: stopNo, stopTag: stopTag, name: stopName, roadName: roadName, location: location)
                
            }
            
            self.delegate?.databaseManagerDidParseDatabase(self, database: stopInformation)

        }
        
        if NSThread.isMainThread() {
            parseBlock()
        } else {
            dispatch_sync(runQueue, parseBlock)
        }
        
    }
    
    func routeCoordinatesForTripIdentifier(tripID: String) -> [CLLocationCoordinate2D]? {
        
        if isConnected == false {
            return nil
        }
        
        var routeTag: String?
        
        for row in (try! database?.prepare("SELECT shape_id FROM trips WHERE trip_id='\(tripID)'"))! {
            routeTag = row[0] as? String
        }
        
        guard routeTag != nil else {
            return nil
        }
        
        guard let statement = try! database?.prepare("SELECT latitude, longitude FROM polyline_points WHERE route_tag='\(routeTag!)'") else {
            return nil
        }
        
        var points: [CLLocationCoordinate2D] = []
        
        for point in statement {
            if point.count < 2 {
                continue
            }
            
            let latitude = (point[0] as! NSString).doubleValue
            let longitude = (point[1] as! NSString).doubleValue
            
            points.append(CLLocationCoordinate2DMake(latitude, longitude))
        }
        
        
        return points
        
    }
    
    func infoForTripIdentifier(tripID: String) -> TripInformation? {
        
        if isConnected == false {
            return nil
        }
        
        guard let statement = try! database?.prepare("SELECT trips.route_id, trip_headsign, route_long_name FROM trips, routes WHERE trips.route_id=routes.route_id AND trip_id='\(tripID)'") else {
            return nil
        }
        
        guard Array(statement).count > 0 else {
            return nil
        }
        
        let tripInfoObject = Array(statement)[0]

        let line = tripInfoObject[2] as! String
        let routeName = tripInfoObject[1] as! String
        let lineType = BusLineType(lineAbbreviationString: tripInfoObject[0] as! String)
        
        return (lineName: line, routeName: routeName, lineType: lineType, tripID: tripID)
        
    }
    
    
    func routesPassingStop(stopNumber: String) -> [TripInformation]? {
        
        if isConnected == false {
            return nil
        }
        
        guard let stopTag = RouteInformationManager.sharedInstance.stopInformation?[stopNumber]?.stopTag else {
            return nil
        }
        
        let routesPassingStopQuery = self.routesPassingStopQuery.stringByReplacingOccurrencesOfString("[stopTag]", withString: stopTag)
        
        guard let statement = try! database?.prepare(routesPassingStopQuery as String) else {
            return nil
        }
        
        return statement.map { row in
            let tripID = row[0] as! String
            let routeID = row[1] as! String
            let lineName = row[2] as! String
            let routeName = row[3] as! String
            
            return (lineType: BusLineType(lineAbbreviationString: routeID), lineName: lineName, routeName: routeName, tripID: tripID)
        }
        
    }
    
    func stopsOnRouteWithTripIdentifier(tripID: String) -> [StopOnRoute]? {
        
        if isConnected == false {
            return nil
        }
        
        //Load the query as it's so big it can't be inlined
        
        let query = self.stopsForTripQuery.stringByReplacingOccurrencesOfString("[tripID]", withString: tripID)
        
        guard let statement = try! database?.prepare(query as String) else {
            return nil
        }
        
        return statement.map { row in
            
            let number = row[0] as! String
            let name = row[1] as! String
            let isMajorStop = row[2] as! String == "1"
            
            return StopOnRoute(stopName: name, stopNumber: number, shouldDisplay: isMajorStop, isIntermediate: false)
            
        }
        
    }
    
    func timetabledTripsForStop(stopNumber: String, afterTime: NSDate) -> TimetabledTripResult {
        
        let components = NSCalendar.currentCalendar().components([.Hour, .Minute, .Second], fromDate: afterTime)
        let secondsFromMidnight = 3600 * components.hour + 60 * components.minute + components.second
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "YYYYMMdd"
        
        let dateString = formatter.stringFromDate(afterTime)
        
        formatter.dateFormat = "EEEE"
        let dayOfWeek = formatter.stringFromDate(afterTime).lowercaseString
        
        var query = timetabledTripsForStopQuery.stringByReplacingOccurrencesOfString("[stopNumber]", withString: stopNumber)
        
        query = query.stringByReplacingOccurrencesOfString("[date]", withString: dateString)
        query = query.stringByReplacingOccurrencesOfString("[dayOfWeek]", withString: dayOfWeek)
        query = query.stringByReplacingOccurrencesOfString("[secondsSinceMidnight]", withString: String(secondsFromMidnight))
        
        guard let trips = try! database?.prepare(query) else {
            return []
        }
        
        var result: TimetabledTripResult = []
        
        for trip in trips {
            
            let tripID = trip[0] as! String
            let arrivalTime = Int(trip[1] as! Int64)
            
            let tripInformation = infoForTripIdentifier(tripID)!
            let eta = Int(ceil(Double(arrivalTime - secondsFromMidnight) / 60.0))
                        
            if eta > 60 {
                break
            }
            
            result.append((trip: tripInformation, eta: eta))
            
        }
        
        return result.sort {
            return $0.0.eta < $0.1.eta
        }
        
    }
    
    
    func coordinatesForRoutes(filterRoutes: [BusLineType] = []) -> [RoutePolylineCoordinates]? {
        
        if isConnected == false {
            return nil
        }
        
        let filterRoutesStringRepresentation = filterRoutes.map { current in
            return current.toString
        }
        
        var values: [RoutePolylineCoordinates] = []
        
        guard let routes = try! database?.prepare("SELECT route_id FROM routes") else {
            return nil
        }

        for route in routes {
            
            let routeName = route[0] as! String
            
            if filterRoutesStringRepresentation.contains(routeName) == false {
                continue
            }
            
            let lineType = BusLineType(lineAbbreviationString: routeName)

            let points = (try! database?.prepare("SELECT trip_id FROM trips WHERE route_id='\(routeName)' GROUP BY direction_id"))!.map { tripRow in
                return routeCoordinatesForTripIdentifier(tripRow[0] as! String)!
            }
            
            values.append((route: lineType, points: points))
            
        }
        
        return values
        
    }
    
    
    func lineColourForRoute(route: BusLineType) -> (text: UIColor?, background: UIColor?) {
        
        guard let statement = try! database?.prepare("SELECT background, text FROM route_colours WHERE route='\(route.toString)'") else {
            return (text: nil, background: nil)
        }
        
        var textColourString: String?
        var backgroundColourString: String?
        
        for lines in statement {
            backgroundColourString = lines[0] as? String
            textColourString = lines[1] as? String
        }
        
        guard textColourString != nil && backgroundColourString != nil else {
            return (text: nil, background: nil)
        }
        
        return (text: UIColor(hex: textColourString!), background: UIColor(hex: backgroundColourString!))
        
    }
    
    
    func rawLinesForStop(stopTag: String) -> [String]? {
        
        if isConnected == false {
            return nil
        }
        
        //Good thing SQL injection here is impossible and useless
        guard let statement = try! database?.prepare("SELECT route_no FROM stop_lines WHERE stop_id='\(stopTag)'") else {
            return nil
        }
        
        return statement.map { lines in
            return lines[0] as! String
        }
        
    }
    
    func executeQuery(sqlQuery: String, completion: Statement -> ()) {
        if isConnected == false {
            return
        }
        
        guard let statement = try! database?.prepare(sqlQuery) else {
            return
        }
        
        completion(statement)
    }
    
    func disconnect() {
        database = nil
        isConnected = false
    }
    
    func connect() {
        if isConnected {
            return
        }
        
        do {
            database = try Connection(DatabaseManager.databasePath)
        } catch {
            isConnected = false
            return
        }
        
        isConnected = true
    }
    
    override init() {
        
        routesPassingStopQuery = try! String(contentsOfFile: NSBundle.mainBundle().pathForResource("routes_passing_stop", ofType: "sql")!, encoding: NSUTF8StringEncoding)
        stopsForTripQuery = try! String(contentsOfFile: NSBundle.mainBundle().pathForResource("find_stops_for_trip", ofType: "sql")!, encoding: NSUTF8StringEncoding)
        timetabledTripsForStopQuery = try! String(contentsOfFile: NSBundle.mainBundle().pathForResource("timetabled_trips_for_stop", ofType: "sql")!, encoding: NSUTF8StringEncoding)
        
        super.init()
        
    }
    
}