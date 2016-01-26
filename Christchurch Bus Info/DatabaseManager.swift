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
    
    private var routesPassingStopQuery: NSString
    private var stopsForTripQuery: NSString
    private var tripIDForRouteQuery: NSString
    
    private var stopUpdateURLs: [String: NSURL] = [:]
    
    var delegate: DatabaseManagerDelegate?
    
    var database: Connection?
    var isConnected = false
    
    lazy var allRoutes: [RouteInformation]? = { [unowned self] in
        
        if self.isConnected == false {
            return nil
        }
        
        let results = self.database?.prepare("SELECT route_id, route_long_name FROM routes")
        var routes: [RouteInformation] = []
            
        for row in results! {
            let routeNumber = row[0] as! String
            let routeName = row[1] as! String
            
            routes.append((lineType: BusLineType(lineAbbreviationString: routeNumber), routeName: routeName))
        }
        
        return routes
        
    }()
    
    lazy var allStops: [[String]]? = { [unowned self] in
        
        if self.isConnected == false {
            return nil
        }
        
        guard let statement = self.database?.prepare("SELECT * FROM stops") else {
            return nil
        }
        
        var returnedColumns: [[String]] = []
        
        for row in statement {
            
            var temp: [String] = []
            
            for column in row {
                let columnValue = column as! String? ?? ""
                temp.append(columnValue)
            }
            
            returnedColumns.append(temp)
        }
        
        return returnedColumns
        
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
        
        for row in (database?.prepare("SELECT shape_id FROM trips WHERE trip_id='\(tripID)'"))! {
            routeTag = row[0] as? String
        }
        
        guard routeTag != nil else {
            return nil
        }
        
        guard let statement = database?.prepare("SELECT latitude, longitude FROM polyline_points WHERE route_tag='\(routeTag!)'") else {
            return nil
        }
        
        var lineCoordinates: [CLLocationCoordinate2D] = []
        
        for point in statement {
            
            if point.count < 2 {
                continue
            }
            
            let latitude = (point[0] as! NSString).doubleValue
            let longitude = (point[1] as! NSString).doubleValue
                
            let coordinate = CLLocationCoordinate2DMake(latitude, longitude)
            lineCoordinates.append(coordinate)
            
        }
        
        return lineCoordinates
        
    }
    
    func infoForTripIdentifier(tripID: String) -> TripInformation? {
        
        if isConnected == false {
            return nil
        }
        
        guard let statement = database?.prepare("SELECT trips.route_id, trip_headsign, route_long_name FROM trips, routes WHERE trips.route_id=routes.route_id AND trip_id='\(tripID)'") else {
            return nil
        }

        let line = Array(statement)[0][2] as! String
        let routeName = Array(statement)[0][1] as! String
        let lineType = BusLineType(lineAbbreviationString: Array(statement)[0][0] as! String)
        
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
        
        guard let statement = database?.prepare(routesPassingStopQuery as String) else {
            return nil
        }
        
        var result: [TripInformation] = []
        
        for row in statement {
            
            let tripID = row[0] as! String
            let routeID = row[1] as! String
            let lineName = row[2] as! String
            let routeName = row[3] as! String
            
            result.append((lineType: BusLineType(lineAbbreviationString: routeID), lineName: lineName, routeName: routeName, tripID: tripID))
            
        }
        
        return result
        
    }
    
    func stopsOnRouteWithTripIdentifier(tripID: String) -> [StopOnRoute]? {
        
        if isConnected == false {
            return nil
        }
        
        //Load the query as it's so big it can't be inlined
        
        let query = self.stopsForTripQuery.stringByReplacingOccurrencesOfString("[tripID]", withString: tripID)
        
        guard let statement = database?.prepare(query as String) else {
            return nil
        }
        
        var result: [StopOnRoute] = []
        
        for rows in statement {
            
            let number = rows[0] as! String
            let name = rows[1] as! String
            let isMajorStop = rows[2] as! String == "1"
            
            result.append(StopOnRoute(stopName: name, stopNumber: number, shouldDisplay: isMajorStop, isIntermediate: false))
            
        }
        
        return result
        
    }
    
    
    func coordinatesForRoutes(filterRoutes: [BusLineType] = []) -> [RoutePolylineCoordinates]? {
        
        if isConnected == false {
            return nil
        }
        
        let filterRoutesStringRepresentation = filterRoutes.map { current in
            return current.toString
        }
        
        var values: [RoutePolylineCoordinates] = []
        
        guard let routes = database?.prepare("SELECT route_id FROM routes") else {
            return nil
        }

        try! database?.execute("CREATE TEMPORARY TABLE IF NOT EXISTS results (trip_id)")
        
        for route in routes {
            
            let routeName = route[0] as! String
            
            if filterRoutesStringRepresentation.contains(routeName) == false {
                continue
            }
            
            let lineType = BusLineType(lineAbbreviationString: routeName)
            var points: [[CLLocationCoordinate2D]] = []
            
            for direction in [0, 1] {
                let query = self.tripIDForRouteQuery.stringByReplacingOccurrencesOfString("[routeID]", withString: routeName)
                try! database?.execute(query.stringByReplacingOccurrencesOfString("[direction]", withString: String(direction)))
            }

            for tripRow in (database?.prepare("SELECT * FROM results"))! {
                points.append(routeCoordinatesForTripIdentifier(tripRow[0] as! String)!)
            }
            
            values.append((route: lineType, points: points))
            
            try! database?.execute("DELETE FROM results")
            
        }
        
        return values
        
    }
    
    
    func lineColourForRoute(route: BusLineType) -> (text: UIColor?, background: UIColor?) {
        
        guard let statement = database?.prepare("SELECT background, text FROM route_colours WHERE route='\(route.toString)'") else {
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
        guard let statement = database?.prepare("SELECT route_no FROM stop_lines WHERE stop_id='\(stopTag)'") else {
            return nil
        }
        
        var toReturn: [String] = []
        
        for lines in statement {
            toReturn.append(lines[0] as! String)
        }
        
        return toReturn
        
    }
    
    func executeQuery(sqlQuery: String, completion: Statement -> ()) {
        if isConnected == false {
            return
        }
        
        guard let statement = database?.prepare(sqlQuery) else {
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
        
        routesPassingStopQuery = try! NSString(contentsOfFile: NSBundle.mainBundle().pathForResource("routes_passing_stop", ofType: "sql")!, encoding: NSUTF8StringEncoding)
        stopsForTripQuery = try! NSString(contentsOfFile: NSBundle.mainBundle().pathForResource("find_stops_for_trip", ofType: "sql")!, encoding: NSUTF8StringEncoding)
        tripIDForRouteQuery = try! NSString(contentsOfFile: NSBundle.mainBundle().pathForResource("trip_id_for_route", ofType: "sql")!, encoding: NSUTF8StringEncoding)
        
        super.init()
        
    }
    
}