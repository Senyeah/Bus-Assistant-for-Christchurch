//
//  RouteInformationManager.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 5/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit
import CoreLocation

let UPDATE_URL = "http://dev.miyazudesign.co.nz/bus/stop_info.php"
let VERSION_URL = "http://dev.miyazudesign.co.nz/bus/stop_info_version.php"

struct StopInformation {
    var stopNo: String
    var stopTag: String
    var name: String
    var location: CLLocation
}

class RouteInformationManager: NSObject {
    
    static let sharedInstance = RouteInformationManager()
    
    let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    var stopInformation: [StopInformation] = []

    override init() {
        
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
        
        do {
            guard let stopsJSON = try NSJSONSerialization.JSONObjectWithData(routeInfoData!, options: NSJSONReadingOptions(rawValue: 0)) as? NSArray else {
                //well shit it failed what do we do now?
                return
            }
            
            for stop in stopsJSON {
                let stopInfo = stop as! NSDictionary
                
                var stopNo: String
                
                if let value = stopInfo["stop_no"] as? String {
                    stopNo = value
                } else {
                    //Stop doesn't exist anymore
                    continue
                }
                
                let stopName = stopInfo["name"] as! String
                let stopTag = stopInfo["stop_tag"] as! String
                
                let location = CLLocation(latitude: stopInfo["latitude"]!.doubleValue!, longitude: stopInfo["longitude"]!.doubleValue!)
                
                stopInformation.append(StopInformation(stopNo: stopNo, stopTag: stopTag, name: stopName, location: location))
            }
        } catch let error as NSError {
            //yeah something went badly wrong
            print("\(error)")
        }
        
    }
    
    func closestStopsForCoordinate(numStops: Int, coordinate: CLLocation) -> [(StopInformation, CLLocationDistance)] {
        
        var candidates: [(StopInformation, CLLocationDistance)] = []
        
        for stop in stopInformation {
            let distance = coordinate.distanceFromLocation(stop.location)
            candidates.append((stop, distance))
        }
        
        candidates.sortInPlace({$0.1 < $1.1})
        
        let itemsToReturn = min(numStops, candidates.count)
        
        return Array(candidates[0..<itemsToReturn])
        
    }
    
}
