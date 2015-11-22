//
//  RouteInformationManager.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 5/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit
import CoreLocation

let UPDATE_URL = "http://metro.miyazudesign.co.nz/latest.php"
let VERSION_URL = "http://metro.miyazudesign.co.nz/version.php"

struct StopInformation {
    var stopNo: String
    var stopTag: String
    var name: String
    var roadName: String
    var location: CLLocation
}

struct StopCoverageInfomation {
    var referencePoint: CLLocation
    var minLat: CLLocationDegrees, maxLat: CLLocationDegrees
    var minLon: CLLocationDegrees, maxLon: CLLocationDegrees
    var coverageWidth: Double, coverageHeight: Double
}

let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]

class RouteInformationManager: NSObject, SSZipArchiveDelegate {
    
    static let sharedInstance = RouteInformationManager()
    
    var stopInformation: [String: StopInformation] = [:]

    private var relativeCoordinates: [(stop: StopInformation, (x: Double, y: Double))] = []
    private var stopsKdTree: COpaquePointer!
    private var coverageInformation: StopCoverageInfomation!
    
    let deviceExpandedDatabasePath = documentsDirectory + "/database.sqlite3"
    
    override init() {
        
        super.init()
        
        //Copy and expand the database from the bundle
        
        let databaseIsInitialised = self.initialiseDatabase()
        
        if databaseIsInitialised {
            parseDatabase()
            updateDatabaseIfNecessary()
            
            initialiseStopInformation()
        }

    }
    
    
    func setDatabaseVersion(newVersion: String) {
        NSUserDefaults.standardUserDefaults().setObject(newVersion, forKey: "database_version")
    }
    
    
    func zipArchiveDidUnzipArchiveAtPath(path: String!, zipInfo: unz_global_info, unzippedPath: String!) {
                
        let expandedDatabaseDirectory = try! NSFileManager.defaultManager().contentsOfDirectoryAtPath(unzippedPath)
        var expandedDatabase: String!
        
        for file in expandedDatabaseDirectory {
            
            if file.hasSuffix("sqlite3") {
                
                var expandedDatabaseVersion = file.stringByReplacingOccurrencesOfString("database-", withString: "")
                expandedDatabaseVersion = expandedDatabaseVersion.stringByReplacingOccurrencesOfString(".sqlite3", withString: "")
                
                expandedDatabase = unzippedPath + "/" + file
                
                setDatabaseVersion(expandedDatabaseVersion)
                
                break
                
            }
            
        }
        
        try! NSFileManager.defaultManager().moveItemAtPath(expandedDatabase, toPath: deviceExpandedDatabasePath)
        
        try! NSFileManager.defaultManager().removeItemAtPath(unzippedPath)
        try! NSFileManager.defaultManager().removeItemAtPath(path)
        
        parseDatabase()
        updateDatabaseIfNecessary()
        initialiseStopInformation()
        
    }
    
    
    func updateDatabaseIfNecessary() {
        
        //Update data if necessary
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
            let updatesAvailable = self.checkForUpdates()
            print("updates available = \(updatesAvailable)")
            
            //(UIApplication.sharedApplication().delegate as! AppDelegate).window!.rootViewController!.performSegueWithIdentifier("ShowUpdateViewSegue", sender: self)
            
        }
        
    }
    
    
    func parseDatabase() {
        //Get the stops from the database
        
        DatabaseManager.sharedInstance.connect()
        
        let stops = DatabaseManager.sharedInstance.listStops()
        let stopAttributes = ["stop_id", "stop_code", "stop_name", "stop_lat", "stop_lon", "stop_url", "road_name"]
        
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

    }
    
    
    func initialiseDatabase() -> Bool {
        
        let bundledDatabasePath = NSBundle.mainBundle().pathForResource("database", ofType: "zip")
        
        let zipFolderExpandedPath = documentsDirectory + "/database"
        
        let deviceCompressedDatabasePath = documentsDirectory + "/database.zip"
        
        if NSFileManager.defaultManager().fileExistsAtPath(deviceExpandedDatabasePath) == false {
            
            do {
                try NSFileManager.defaultManager().copyItemAtPath(bundledDatabasePath!, toPath: deviceCompressedDatabasePath)
            } catch let error as NSError {
                print("well shit, \(error)")
            }
            
            SSZipArchive.unzipFileAtPath(deviceCompressedDatabasePath, toDestination: zipFolderExpandedPath, delegate: self)
            
            return false
            
        } else {
            return true
        }
        
    }
    
    
    func checkForUpdates() -> Bool {
        
        let latestVersionData = NSData(contentsOfURL: NSURL(string: VERSION_URL)!)
        let latestVersion = NSString(data: latestVersionData!, encoding: NSUTF8StringEncoding)!
        
        let currentVersion = NSUserDefaults.standardUserDefaults().objectForKey("database_version")
        
        return !latestVersion.isEqualToString(currentVersion as! String)
        
    }
    
    
    func priorityForRoute(line: BusLineType) -> Int? {
        switch line {
        case .PurpleLine:
            return 6
        case .OrangeLine:
            return 5
        case .YellowLine:
            return 4
        case .BlueLine:
            return 3
        case .Orbiter(.Clockwise):
            return 2
        case .Orbiter(.AntiClockwise):
            return 1
        default:
            return nil
        }
    }
    
    
    func linesForStop(stopTag: String) -> [BusLineType] {
        
        let lines = DatabaseManager.sharedInstance.rawLinesForStop(stopTag)
        var lineArray: [BusLineType] = []
        
        for line in lines {
            lineArray.append(busLineTypeForString(line))
        }
        
        lineArray.sortInPlace({
            let priority1 = priorityForRoute($0)
            let priority2 = priorityForRoute($1)
            
            if priority1 != nil && priority2 == nil {
                return true
            } else if priority2 != nil && priority1 == nil {
                return false
            } else if priority1 != nil && priority2 != nil {
                return priority2 < priority1
            } else {
                var tag1: Int!
                var tag2: Int!
                
                switch $0 {
                case .NumberedRoute(let tag):
                    tag1 = Int(tag)
                default:
                    break
                }
                
                switch $1 {
                case .NumberedRoute(let tag):
                    tag2 = Int(tag)
                default:
                    break
                }
                
                return tag1 < tag2
            }
        })
        
        return lineArray
        
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
    
    //Convert a latitude, longitude coordinate to a point mapping on a cartesian plane
    
    private func normaliseCoordinate(coordinate: CLLocationCoordinate2D, coverage: StopCoverageInfomation) -> (x: Double, y: Double) {
        
        let longitudeDeltaLocation = CLLocation(latitude: coverage.minLat, longitude: coordinate.longitude)
        let latitudeDeltaLocation = CLLocation(latitude: coordinate.latitude, longitude: coverage.minLon)
        
        let normalisedLongitude = coverage.referencePoint.distanceFromLocation(longitudeDeltaLocation) / coverage.coverageWidth
        let normalisedLatitude = coverage.referencePoint.distanceFromLocation(latitudeDeltaLocation) / coverage.coverageHeight
        
        return (x: normalisedLongitude, y: normalisedLatitude)
        
    }
    
    
    //Converts from latitude-longitude to a relative coordinate based on the stop
    //with the smallest x- and y-coordinate so it can be used in a kd-tree
    
    private func relativeCoordinatesForStops() -> [(stop: StopInformation, (x: Double, y: Double))] {
        
        var latitudes: [CLLocationDegrees] = []
        var longitudes: [CLLocationDegrees] = []
        
        for (_, info) in stopInformation {
            latitudes.append(info.location.coordinate.latitude)
            longitudes.append(info.location.coordinate.longitude)
        }
        
        let (minLat, maxLat) = (latitudes.minElement()!, latitudes.maxElement()!)
        let (minLon, maxLon) = (longitudes.minElement()!, longitudes.maxElement()!)
        
        let referencePoint = CLLocation(latitude: minLat, longitude: minLon)
        
        let coverageWidth = referencePoint.distanceFromLocation(CLLocation(latitude: minLat, longitude: maxLon))
        let coverageHeight = referencePoint.distanceFromLocation(CLLocation(latitude: maxLat, longitude: minLon))
        
        self.coverageInformation = StopCoverageInfomation(referencePoint: referencePoint, minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon, coverageWidth: coverageWidth, coverageHeight: coverageHeight)
        
        var normalisedCoordinates: [(stop: StopInformation, (x: Double, y: Double))] = []
            
        for (_, info) in stopInformation {
            
            let coordinate = info.location.coordinate
            let normalisedCoordinate = normaliseCoordinate(coordinate, coverage: self.coverageInformation)
            
            normalisedCoordinates.append((stop: info, normalisedCoordinate))
            
        }
        
        return normalisedCoordinates

    }
    
    //Constructs a kd-tree of the stops
    
    private func kdTreeForStops(relativeStops: [(stop: StopInformation, (x: Double, y: Double))]) -> COpaquePointer {
        
        //Create a 2-dimensional tree
        
        let tree = kd_create(2)
        
        for (stop, coordinate) in relativeStops {
            
            let coordinatePointer = UnsafeMutablePointer<Double>.alloc(2)
            coordinatePointer.initializeFrom([coordinate.x, coordinate.y])
            
            let stopPointer = UnsafeMutablePointer<StopInformation>.alloc(1)
            stopPointer.initialize(stop)
            
            kd_insert(tree, coordinatePointer, stopPointer)
                        
        }
        
        return tree
        
    }
    
    
    func closestStopsForLocation(radiusInMetres: Double, location: CLLocation) -> [(stop: StopInformation, distance: CLLocationDistance)] {
        
        let normalisedCoordinate = self.normaliseCoordinate(location.coordinate, coverage: self.coverageInformation)
        
        let coordinatePointer = UnsafeMutablePointer<Double>.alloc(2)
        coordinatePointer.initializeFrom([normalisedCoordinate.x, normalisedCoordinate.y])
        
        //This isn't entirely accurate but oh well
        
        let radius = radiusInMetres / min(self.coverageInformation.coverageWidth, self.coverageInformation.coverageHeight)
        
        let resultingStops = kd_nearest_range(stopsKdTree!, coordinatePointer, radius)
        var resultingStopsArray: [(stop: StopInformation, distance: CLLocationDistance)] = []
        
        while kd_res_end(resultingStops) == 0 {
            
            let returnedStopPointer = kd_res_item(resultingStops, UnsafeMutablePointer<Double>.init())
            let returnedStop = UnsafePointer<StopInformation>(returnedStopPointer).memory
            
            let distanceFromStop = location.distanceFromLocation(returnedStop.location)
            resultingStopsArray.append((stop: returnedStop, distance: distanceFromStop))
                        
            kd_res_next(resultingStops)
            
        }
        
        coordinatePointer.dealloc(2)
        
        return resultingStopsArray
        
    }
    
    
    private func initialiseStopInformation() {
        
        relativeCoordinates.removeAll()
        relativeCoordinates = relativeCoordinatesForStops()
        
        stopsKdTree = kdTreeForStops(relativeCoordinates)
        
    }
    
}
