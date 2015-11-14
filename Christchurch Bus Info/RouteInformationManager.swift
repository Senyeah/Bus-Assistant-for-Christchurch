//
//  RouteInformationManager.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 5/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit
import CoreLocation

//Todo:

let UPDATE_URL = "http://dev.miyazudesign.co.nz/bus/stop_info.php"
let VERSION_URL = "http://dev.miyazudesign.co.nz/bus/stop_info_version.php"

struct StopInformation {
    var stopNo: String
    var stopTag: String
    var name: String
    var roadName: String
    var location: CLLocation
    var lines: [BusLineType]
}

class RouteInformationManager: NSObject {
    
    static let sharedInstance = RouteInformationManager()
    
    let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    var stopInformation = [String: StopInformation]()

    
    override init() {
        
        super.init()
        
        //Check to see if we've copied the timetable from the bundle to somewhere we can modify it
        
        let expectedPath = documentsDirectory + "/stop_information.json"
        
        //Copy it from the bundle to the documents directory
        
        if NSFileManager.defaultManager().fileExistsAtPath(expectedPath) == false {
            let defaultInfoPath = NSBundle.mainBundle().pathForResource("stop_information", ofType: "json")
            try! NSFileManager.defaultManager().copyItemAtPath(defaultInfoPath!, toPath: expectedPath)
        }
        
        //Check for an update, but at some point this should be async to avoid delay
        
        //todo
        
        let routeInfoData = NSData.init(contentsOfFile: expectedPath)
        let stopsJSON: NSDictionary = try! NSJSONSerialization.JSONObjectWithData(routeInfoData!, options: NSJSONReadingOptions(rawValue: 0)) as! NSDictionary

        for (stopNumber, info) in stopsJSON {
            
            let stopInfo = info as! NSDictionary
                
            let stopName = stopInfo["name"] as! String
            let stopTag = stopInfo["stop_tag"] as! String
            
            let roadName = stopInfo["road_name"] as! String
            
            let location = CLLocation(latitude: stopInfo["latitude"]!.doubleValue!, longitude: stopInfo["longitude"]!.doubleValue!)
            
            let linesStrings = stopInfo["lines"] as! NSArray
            var lines: [BusLineType] = []
            
            for lineString in linesStrings {
                lines.append(self.busLineTypeForString(lineString as! String))
            }
            
            stopInformation[stopNumber as! String] = StopInformation(stopNo: stopNumber as! String, stopTag: stopTag, name: stopName, roadName: roadName, location: location, lines: lines)
            
        }
        
    }
    
    
    func stopInformationForStopNumber(number: String) -> StopInformation? {
        return stopInformation[number]
    }
    
    
    func busLineTypeForString(inString: String) -> BusLineType {
        
        let linesMap: [String: BusLineType] = ["P": .PurpleLine, "O": .OrangeLine, "Y": .YellowLine, "B": .BlueLine, "Oa": .Orbiter(.AntiClockwise), "Oc": .Orbiter(.Clockwise)]
        
        var lineType: BusLineType?
        
        if linesMap[inString] == nil {
            lineType = .NumberedRoute(inString)
        } else {
            lineType = linesMap[inString]
        }
        
        return lineType!
        
    }
    
    
    func closestStopsForCoordinate(numStops: Int, coordinate: CLLocation) -> [(StopInformation, CLLocationDistance)] {
        
        var candidates: [(StopInformation, CLLocationDistance)] = []
        
        for (_, stopInfo) in stopInformation {
            let distance = coordinate.distanceFromLocation(stopInfo.location)
            candidates.append((stopInfo, distance))
        }
        
        candidates.sortInPlace({$0.1 < $1.1})
        
        let itemsToReturn = min(numStops, candidates.count)

        return Array(candidates[0..<itemsToReturn])
        
    }
    
}
