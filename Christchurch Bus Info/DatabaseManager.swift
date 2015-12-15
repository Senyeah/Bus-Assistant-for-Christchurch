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
    func databaseManagerDidParseDatabase(manager: DatabaseManager, database: [String : StopInformation])
}

let DOCUMENTS_DIRECTORY = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]

class DatabaseManager: NSObject {

    static let sharedInstance = DatabaseManager()
    static let databasePath = DOCUMENTS_DIRECTORY + "/database.sqlite3"
    
    var delegate: DatabaseManagerDelegate?
    
    var database: Connection?
    var isConnected = false
    
    var stopTagNumbers: [String: String] = [:]
    
    func parseDatabase(runQueue: dispatch_queue_t = dispatch_get_main_queue()) {
        
        if isConnected == false {
            return
        }
        
        let parseBlock: () -> Void = {
            
            guard let stops = self.listStops() else {
                return
            }
            
            let stopAttributes = ["stop_id", "stop_code", "stop_name", "stop_lat", "stop_lon", "stop_url", "road_name"]
            
            var stopInformation: [String : StopInformation] = [:]
            
            for stop in stops {
                
                let latitude = CLLocationDegrees(stop[stopAttributes.indexOf("stop_lat")!])!
                let longitude = CLLocationDegrees(stop[stopAttributes.indexOf("stop_lon")!])!
                
                let location = CLLocation(latitude: latitude, longitude: longitude)
                
                let stopNo = stop[stopAttributes.indexOf("stop_code")!]
                let stopTag = stop[stopAttributes.indexOf("stop_id")!]
                let stopName = stop[stopAttributes.indexOf("stop_name")!]
                
                self.stopTagNumbers[stopTag] = stopNo
                
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
        
        guard let statement = database?.prepare("SELECT latitude, longitude FROM polyline_points") else {
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
    
    func infoForTripIdentifier(tripID: String) -> (lineName: String, routeName: String, lineType: BusLineType)? {
        
        if isConnected == false {
            return nil
        }
        
        guard let statement = database?.prepare("SELECT trips.route_id, trip_headsign, route_long_name FROM trips, routes WHERE trips.route_id=routes.route_id AND trip_id='\(tripID)'") else {
            return nil
        }

        let line = Array(statement)[0][2] as! String
        let routeName = Array(statement)[0][1] as! String
        let lineType = RouteInformationManager.sharedInstance.busLineTypeForString(Array(statement)[0][0] as! String)
        
        return (lineName: line, routeName: routeName, lineType: lineType)
        
    }
    
    
    func stopsOnRouteWithTripIdentifier(tripID: String) -> [StopOnRoute]? {
        
        if isConnected == false {
            return nil
        }
        
        //Load the query as it's so big it can't be inlined
        
        var query = try! NSString(contentsOfFile: NSBundle.mainBundle().pathForResource("find_stops_for_trip", ofType: "sql")!, encoding: NSUTF8StringEncoding)
        query = query.stringByReplacingOccurrencesOfString("[tripID]", withString: tripID)
        
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
    
    func listStops() -> [[String]]? {
        
        if isConnected == false {
            return nil
        }
        
        guard let statement = database?.prepare("SELECT * FROM stops") else {
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
        super.init()
    }
    
}