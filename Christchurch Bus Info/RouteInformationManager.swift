//
//  RouteInformationManager.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 5/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

struct StopInformation {
    var stopNo: String, stopTag: String
    var name: String, roadName: String
    var location: CLLocation
}

struct StopCoverageInfomation {
    var referencePoint: CLLocation
    var minLat: CLLocationDegrees, maxLat: CLLocationDegrees
    var minLon: CLLocationDegrees, maxLon: CLLocationDegrees
    var coverageWidth: Double, coverageHeight: Double
}

protocol RouteInformationManagerDelegate {
    func managerReceivedUpdatedInformation(manager: RouteInformationManager)
}

class RouteInformationManager: NSObject, UpdateManagerDelegate, DatabaseManagerDelegate {
    
    static let sharedInstance = RouteInformationManager()
    
    var stopInformation: [String: StopInformation]?
    var delegate: RouteInformationManagerDelegate?
    
    var progressViewController: DownloadUpdateViewController?
    
    private var relativeCoordinates: [(stop: StopInformation, (x: Double, y: Double))] {
        get {
            var normalisedCoordinates: [(stop: StopInformation, (x: Double, y: Double))] = []
            
            for (_, info) in stopInformation! {
                let coordinate = info.location.coordinate
                let normalisedCoordinate = normaliseCoordinate(coordinate, coverage: self.coverageInformation)
                
                normalisedCoordinates.append((stop: info, normalisedCoordinate))
            }
            
            return normalisedCoordinates
        }
    }
    
    private lazy var stopsKdTree: COpaquePointer = { [unowned self] in
        return self.kdTreeForStops(self.relativeCoordinates)
    }()
    
    private lazy var coverageInformation: StopCoverageInfomation = computeCoverageInformation(self)()
    
    override init() {
        super.init()
    }
    
    func initialise() {
        UpdateManager.sharedInstance.delegate = self
        DatabaseManager.sharedInstance.delegate = self
        
        UpdateManager.sharedInstance.initialise()
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
        
        guard let lines = DatabaseManager.sharedInstance.rawLinesForStop(stopTag) else {
            return []
        }
        
        var lineArray: [BusLineType] = []
        
        for line in lines {
            lineArray.append(BusLineType(lineAbbreviationString: line))
        }
        
        lineArray.sortInPlace({
            
            let (priority1, priority2) = (priorityForRoute($0), priorityForRoute($1))
            
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
    
    
    func displayStringForStopNumber(stopNumber: String) -> String {
        
        guard let stopInfo = stopInformation![stopNumber] else {
            return ""
        }
        
        if stopInfo.name == stopInfo.roadName {
            return stopInfo.name
        } else {
            return "\(stopInfo.roadName) near \(stopInfo.name)"
        }
        
    }
    
    
    func stopInformationForStopNumber(number: String) -> StopInformation? {
        return stopInformation?[number]
    }
    
    
    //Convert a latitude, longitude coordinate to a point mapping on a cartesian plane
    
    private func normaliseCoordinate(coordinate: CLLocationCoordinate2D, coverage: StopCoverageInfomation) -> (x: Double, y: Double) {
        
        let longitudeDeltaLocation = CLLocation(latitude: coverage.minLat, longitude: coordinate.longitude)
        let latitudeDeltaLocation = CLLocation(latitude: coordinate.latitude, longitude: coverage.minLon)
        
        let normalisedLongitude = coverage.referencePoint.distanceFromLocation(longitudeDeltaLocation) / coverage.coverageWidth
        let normalisedLatitude = coverage.referencePoint.distanceFromLocation(latitudeDeltaLocation) / coverage.coverageHeight
        
        return (x: normalisedLongitude, y: normalisedLatitude)
        
    }
    
    
    private func computeCoverageInformation() -> StopCoverageInfomation {
        
        var latitudes: [CLLocationDegrees] = []
        var longitudes: [CLLocationDegrees] = []
        
        guard stopInformation != nil else {
            fatalError("It's nil, shit! (computeCoverageInformation)")
        }
        
        for (_, info) in stopInformation! {
            latitudes.append(info.location.coordinate.latitude)
            longitudes.append(info.location.coordinate.longitude)
        }
        
        let (minLat, maxLat) = (latitudes.minElement()!, latitudes.maxElement()!)
        let (minLon, maxLon) = (longitudes.minElement()!, longitudes.maxElement()!)
        
        let referencePoint = CLLocation(latitude: minLat, longitude: minLon)
        
        let coverageWidth = referencePoint.distanceFromLocation(CLLocation(latitude: minLat, longitude: maxLon))
        let coverageHeight = referencePoint.distanceFromLocation(CLLocation(latitude: maxLat, longitude: minLon))
        
        return StopCoverageInfomation(referencePoint: referencePoint, minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon, coverageWidth: coverageWidth, coverageHeight: coverageHeight)
        
    }
    
    
    //Converts from latitude-longitude to a relative coordinate based on the stop
    //with the smallest x- and y-coordinate so it can be used in a kd-tree
    
    private func relativeCoordinatesForStops() -> [(stop: StopInformation, (x: Double, y: Double))] {
        
        var normalisedCoordinates: [(stop: StopInformation, (x: Double, y: Double))] = []
        
        guard stopInformation != nil else {
            fatalError("It's nil, shit! (relativeCoordinatesForStops)")
        }
        
        for (_, info) in stopInformation! {
            
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
        
        let resultingStops = kd_nearest_range(stopsKdTree, coordinatePointer, radius)
        var resultingStopsArray: [(stop: StopInformation, distance: CLLocationDistance)] = []
        
        while kd_res_end(resultingStops) == 0 {
            
            let returnedStopPointer = kd_res_item(resultingStops, UnsafeMutablePointer<Double>.init())
            let returnedStop = UnsafePointer<StopInformation>(returnedStopPointer).memory
            
            let distanceFromStop = location.distanceFromLocation(returnedStop.location)
            resultingStopsArray.append((stop: returnedStop, distance: distanceFromStop))
            
            kd_res_next(resultingStops)
            
        }
        
        kd_res_free(resultingStops)
        coordinatePointer.dealloc(2)
        
        return resultingStopsArray
        
    }
    
    func projectedMapSpanForMapRect(mapRect: MKMapRect) -> ProjectedMapSpan {
        
        let minLongitude = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMinX(mapRect), MKMapRectGetMidY(mapRect)))
        let maxLongitude = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMaxX(mapRect), MKMapRectGetMidY(mapRect)))
        
        let minLonLocation = CLLocation(latitude: minLongitude.latitude, longitude: minLongitude.longitude)
        let maxLonLocation = CLLocation(latitude: minLongitude.latitude, longitude: maxLongitude.longitude)
        
        let longitudeSpan = minLonLocation.distanceFromLocation(maxLonLocation)
        
        let minLatitude = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMidX(mapRect), MKMapRectGetMinY(mapRect)))
        let maxLatitude = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMidX(mapRect), MKMapRectGetMaxY(mapRect)))
        
        let minLatLocation = CLLocation(latitude: minLatitude.latitude, longitude: minLatitude.longitude)
        let maxLatLocation = CLLocation(latitude: maxLatitude.latitude, longitude: maxLatitude.longitude)
        
        let latitudeSpan = minLatLocation.distanceFromLocation(maxLatLocation)
        
        return (horizontalDistance: longitudeSpan, verticalDistance: latitudeSpan)
        
    }
    
    func stopsInRegion(region: MKMapRect) -> [StopInformation] {
        
        let coordinateRegion = MKCoordinateRegionForMapRect(region)
        let mapSpan = projectedMapSpanForMapRect(region)
        
        let searchRadius = max(mapSpan.horizontalDistance, mapSpan.verticalDistance)
        
        let centrePoint = MKMapPointForCoordinate(coordinateRegion.center)
        let stopsInRadius = self.closestStopsForLocation(searchRadius, location: CLLocation(latitude: coordinateRegion.center.latitude, longitude: coordinateRegion.center.longitude))
        
        var stopsInRect: [StopInformation] = []
        
        for (stop, _) in stopsInRadius {
            //if MKMapRectContainsPoint(region, centrePoint) {
                stopsInRect.append(stop)
            //}
        }
        
        return stopsInRect
        
    }
    
    func databaseManagerDidParseDatabase(manager: DatabaseManager, database: [String: StopInformation]) {
        stopInformation = database
        delegate?.managerReceivedUpdatedInformation(self)
    }
    
    func updateManagerWillDownloadFile(manager: UpdateManager) {
        
        let shouldDisplayProgressView = false
        
        if shouldDisplayProgressView {
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let rootViewController = appDelegate.window!.rootViewController
            
            dispatch_async(dispatch_get_main_queue()) { _ -> Void in
                rootViewController!.performSegueWithIdentifier("ShowUpdateViewSegue", sender: self)
            }
            
        }
        
    }
    
    func updateManagerIsDownloadingFileWithProgress(manager: UpdateManager, progress: Double, currentSize: Int64, maxSize: Int64) {
        
        dispatch_async(dispatch_get_main_queue()) { _ -> Void in
            
            let currentSizeFormatted = NSByteCountFormatter.stringFromByteCount(currentSize, countStyle: .File)
            let totalSizeFormatted = NSByteCountFormatter.stringFromByteCount(maxSize, countStyle: .File)
            
            self.progressViewController?.progressLabel.text = currentSizeFormatted + " of " + totalSizeFormatted
            self.progressViewController?.progressBar.progress = Float(progress)
            
        }
        
    }
    
    func updateManagerDidCompleteDownload(manager: UpdateManager, error: NSError?) {
        print("completed download! yay!")
        
        dispatch_async(dispatch_get_main_queue()) { _ -> Void in
            self.delegate?.managerReceivedUpdatedInformation(self)
        }
    }
    
    func updateManagerWillExtractUpdate(manager: UpdateManager) {
        print("extracting update...")
    }
    
    func updateManagerDidExtractUpdate(manager: UpdateManager, extractionFailed: Bool) {
        print("extracted update with failure = \(extractionFailed)")
        
        if extractionFailed == false {
            dispatch_async(dispatch_get_main_queue()) { _ -> Void in
                self.progressViewController?.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
            }
        }
        
    }
    
}
