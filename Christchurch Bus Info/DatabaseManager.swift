//
//  DatabaseManager.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 15/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit
import SQLite


struct StopOnRoute {
    var stopName: String
    var stopNumber: String
    var isMajorStop: Bool
}


class DatabaseManager: NSObject {

    static let sharedInstance = DatabaseManager()
    let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    
    var database: Connection!
    
    
    func infoForTripIdentifier(tripID: String) -> (lineName: String, routeName: String, lineType: BusLineType) {
        
        let statement = database.prepare("SELECT trips.route_id, trip_headsign, route_long_name FROM trips, routes WHERE trips.route_id=routes.route_id AND trip_id='\(tripID)'")

        let line = Array(statement)[0][2] as! String
        let routeName = Array(statement)[0][1] as! String
        let lineType = RouteInformationManager.sharedInstance.busLineTypeForString(Array(statement)[0][0] as! String)
        
        return (lineName: line, routeName: routeName, lineType: lineType)
        
    }
    
    
    func stopsOnRouteWithTripIdentifier(tripID: String) -> [StopOnRoute] {
        
        //Load the query as it's so big it can't be inlined
        
        var query = try! NSString(contentsOfFile: NSBundle.mainBundle().pathForResource("find_stops_for_trip", ofType: "sql")!, encoding: NSUTF8StringEncoding)
        query = query.stringByReplacingOccurrencesOfString("[tripID]", withString: tripID)
        
        let statement = database.prepare(query as String)
        
        var result: [StopOnRoute] = []
        
        for rows in statement {
            
            let number = rows[0] as! String
            let name = rows[1] as! String
            let isMajorStop = rows[2] as! String == "1"
            
            result.append(StopOnRoute(stopName: name, stopNumber: number, isMajorStop: isMajorStop))
            
        }
        
        return result
        
    }
    
    
    func rawLinesForStop(stopTag: String) -> [String] {
        
        //Good thing SQL injection here is impossible and useless
        
        let statement = database.prepare("SELECT route_no FROM stop_lines WHERE stop_id='\(stopTag)'")
        
        var toReturn: [String] = []
        
        for lines in statement {
            toReturn.append(lines[0] as! String)
        }
        
        return toReturn
        
    }
    
    func listStops() -> [[String]] {
        
        let statement = database.prepare("SELECT * FROM stops")
        var returnedColumns: [[String]] = []
        
        for row in statement {
            
            var temp: [String] = []
            
            for column in row {
                
                if column == nil {
                    temp.append("")
                } else {
                    temp.append(column as! String)
                }
                
                
            }
            
            returnedColumns.append(temp)
        }
        
        return returnedColumns
        
    }
    
    override init() {
        super.init()
        database = try! Connection(documentsDirectory + "/database.sqlite")
    }
    
}
