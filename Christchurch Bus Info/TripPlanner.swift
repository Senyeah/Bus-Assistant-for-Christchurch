//
//  TripPlanner.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 12/12/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit
import CoreLocation

protocol TripPlannerDelegate {
    func tripPlannerDidBegin(planner: TripPlanner)
    func tripPlannerDidCompleteWithError(planner: TripPlanner?, error: TripPlannerError)
    func tripPlannerDidCompleteSuccessfully(planner: TripPlanner, journey: [TripPlannerJourney])
}

enum TripPlannerError {
    case VersionError
    case ConnectionError
    case ParseError
}

class TripPlannerSegment: NSObject, NSCoding {
    
    var isBusJourney: Bool
    var route: BusLineType? = nil
    var tripID: String?
    
    var startTime: NSDate
    var endTime: NSDate
    var duration: Int
    
    var startPosition: CLLocationCoordinate2D
    var endPosition: CLLocationCoordinate2D
    
    var startStop: String?
    var endStop: String?
    
    var polylinePoints: [CLLocationCoordinate2D]
    
    init(isBusJourney: Bool, route: BusLineType?, tripID: String?,
         startTime: NSDate, endTime: NSDate, duration: Int,
         startPosition: CLLocationCoordinate2D, endPosition: CLLocationCoordinate2D,
         startStop: String?, endStop: String?, polylinePoints: [CLLocationCoordinate2D]) {
        
        self.isBusJourney = isBusJourney
        self.route = route
        self.tripID = tripID
            
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        
        self.startPosition = startPosition
        self.endPosition = endPosition
        
        self.startStop = startStop
        self.endStop = endStop
        
        self.polylinePoints = polylinePoints
            
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        
        aCoder.encodeBool(self.isBusJourney, forKey: "isBusJourney")
        aCoder.encodeObject(self.route?.toString, forKey: "route")
        aCoder.encodeObject(self.tripID, forKey: "tripID")
        
        aCoder.encodeObject(self.startTime, forKey: "startTime")
        aCoder.encodeObject(self.endTime, forKey: "endTime")
        aCoder.encodeInteger(self.duration, forKey: "duration")
  
        aCoder.encodeObject(CLLocation(latitude: self.startPosition.latitude, longitude: self.startPosition.longitude), forKey: "startPosition")
        aCoder.encodeObject(CLLocation(latitude: self.endPosition.latitude, longitude: self.endPosition.longitude), forKey: "endPosition")
        
        aCoder.encodeObject(self.startStop, forKey: "startStop")
        aCoder.encodeObject(self.endStop, forKey: "endStop")
        
        let polylinePointsValuesArray = self.polylinePoints.map { point in
            return CLLocation(latitude: point.latitude, longitude: point.longitude)
        }
        
        aCoder.encodeObject(polylinePointsValuesArray, forKey: "polylinePoints")
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        self.isBusJourney = aDecoder.decodeBoolForKey("isBusJourney")
        
        let segmentRoute = aDecoder.decodeObjectForKey("route") as! String?
        
        if segmentRoute != nil {
            self.route = BusLineType(lineAbbreviationString: segmentRoute!)
        }
        
        self.tripID = aDecoder.decodeObjectForKey("tripID") as! String?
        
        self.startTime = aDecoder.decodeObjectForKey("startTime") as! NSDate
        self.endTime = aDecoder.decodeObjectForKey("endTime") as! NSDate
        self.duration = aDecoder.decodeIntegerForKey("duration")
        
        let startPositionValue = aDecoder.decodeObjectForKey("startPosition") as! CLLocation
        let endPositionValue = aDecoder.decodeObjectForKey("endPosition") as! CLLocation
        
        self.startPosition = startPositionValue.coordinate
        self.endPosition = endPositionValue.coordinate
        
        self.startStop = aDecoder.decodeObjectForKey("startStop") as! String?
        self.endStop = aDecoder.decodeObjectForKey("endStop") as! String?

        let polylinePointsArray = aDecoder.decodeObjectForKey("polylinePoints") as! [CLLocation]

        self.polylinePoints = polylinePointsArray.map { value in
            return value.coordinate
        }
        
    }
    
}

class TripPlannerJourney: NSObject, NSCoding {
    
    var startTime: NSDate
    var finishTime: NSDate
    
    var startLocationString: String?
    var endLocationString: String?
    
    var walkTime: Int
    var transitTime: Int
    var duration: Int
    
    var segments: [TripPlannerSegment]
    var routes: [BusLineType]
    
    init(startTime: NSDate, finishTime: NSDate,
         startLocationString: String?, endLocationString: String?,
         walkTime: Int, transitTime: Int, duration: Int,
         segments: [TripPlannerSegment], routes: [BusLineType]) {
            
        self.startTime = startTime
        self.finishTime = finishTime
        
        self.startLocationString = startLocationString
        self.endLocationString = endLocationString
        
        self.walkTime = walkTime
        self.transitTime = transitTime
        self.duration = duration
        
        self.segments = segments
        self.routes = routes
        
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        
        aCoder.encodeObject(self.startTime, forKey: "startTime")
        aCoder.encodeObject(self.finishTime, forKey: "finishTime")
        
        aCoder.encodeObject(self.startLocationString, forKey: "startLocationString")
        aCoder.encodeObject(self.endLocationString, forKey: "endLocationString")
        
        aCoder.encodeInteger(self.walkTime, forKey: "walkTime")
        aCoder.encodeInteger(self.transitTime, forKey: "transitTime")
        aCoder.encodeInteger(self.duration, forKey: "duration")
        
        aCoder.encodeObject(self.segments, forKey: "segments")
        
        let encodedRoutes = self.routes.map { route in
            return route.toString
        }
        
        aCoder.encodeObject(encodedRoutes, forKey: "routes")
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        self.startTime = aDecoder.decodeObjectForKey("startTime") as! NSDate
        self.finishTime = aDecoder.decodeObjectForKey("finishTime") as! NSDate
        
        self.startLocationString = aDecoder.decodeObjectForKey("startLocationString") as! String?
        self.endLocationString = aDecoder.decodeObjectForKey("endLocationString") as! String?
        
        self.walkTime = aDecoder.decodeIntegerForKey("walkTime")
        self.transitTime = aDecoder.decodeIntegerForKey("transitTime")
        self.duration = aDecoder.decodeIntegerForKey("duration")
        
        self.segments = aDecoder.decodeObjectForKey("segments") as! [TripPlannerSegment]
        
        let encodedRoutes = aDecoder.decodeObjectForKey("routes") as! [String]
        
        self.routes = encodedRoutes.map { route in
            return BusLineType(lineAbbreviationString: route)
        }
        
    }
    
}

class TripPlanner: NSObject {
    
    private var startPosition: CLLocation
    private var endPosition: CLLocation
    
    private var startTime: NSDate
    private var delegate: TripPlannerDelegate
    
    private lazy var requestURL: NSURL = { [unowned self] in
        let (dateString, timeString) = self.startTime.toDateTimeString()
        let (startPosString, endPosString) = (self.startPosition.coordinate.stringValue, self.endPosition.coordinate.stringValue)

        return NSURL(string: "https://busassistant.xyz/trip_planner.php?from=\(startPosString)&to=\(endPosString)&date=\(dateString)&time=\(timeString)")!
    }()
    
    static var canAccessServer: Bool {
        guard let _ = NSData(contentsOfURL: NSURL(string: "https://busassistant.xyz/")!) else {
            return false
        }
        
        return true
    }
    
    init(start: CLLocation, end: CLLocation, time: NSDate, updateDelegate: TripPlannerDelegate) {
        
        startPosition = start
        endPosition = end
        
        startTime = time
        delegate = updateDelegate
        
        super.init()
        delegate.tripPlannerDidBegin(self)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            guard let receivedJSONData = NSData(contentsOfURL: self.requestURL) else {
                dispatch_async(dispatch_get_main_queue()) {
                    self.delegate.tripPlannerDidCompleteWithError(self, error: .ConnectionError)
                }
                
                return
            }
            
            do {
                guard let journeyArray = try NSJSONSerialization.JSONObjectWithData(receivedJSONData, options: NSJSONReadingOptions(rawValue: 0)) as? NSArray else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.delegate.tripPlannerDidCompleteWithError(self, error: .ParseError)
                    }
                    
                    return
                }
                
                var trips: [TripPlannerJourney] = []
                
                for item in journeyArray {
                    
                    let info = item as! [String: AnyObject]
                    
                    let startTime = NSDate.representationToDate(info["start_time"] as! String)
                    let finishTime = NSDate.representationToDate(info["finish_time"] as! String)
                    let duration = (info["duration"] as! NSNumber).integerValue
                    
                    let walkTime = (info["walk_time"] as! NSNumber).integerValue
                    let transitTime = (info["transit_time"] as! NSNumber).integerValue
                    
                    var segments: [TripPlannerSegment] = []
                    var routes: [BusLineType] = []
                    
                    for segment in info["segments"] as! NSArray {
                        
                        let segmentInfo = segment as! [String: AnyObject]
                        
                        let isBusSegment = (segmentInfo["type"] as! String) == "bus"
                        let segmentDuration = (segmentInfo["duration"] as! NSNumber).integerValue
                        
                        let segmentStart = NSDate.representationToDate(segmentInfo["start_time"] as! String)
                        let segmentEnd = NSDate.representationToDate(segmentInfo["finish_time"] as! String)
                        
                        let segmentSourceInfo = segment["from"] as! NSDictionary
                        let segmentDestInfo = segment["to"] as! NSDictionary

                        let fromPoint = CLLocationCoordinate2D(latitude: (segmentSourceInfo["lat"] as! NSNumber).doubleValue, longitude: (segmentSourceInfo["lon"] as! NSNumber).doubleValue)
                        var fromStop: String? = nil
                        
                        if segmentSourceInfo.objectForKey("stop") != nil {
                            fromStop = segmentSourceInfo["stop"] as? String
                        }
                        
                        let toPoint = CLLocationCoordinate2D(latitude: (segmentDestInfo["lat"] as! NSNumber).doubleValue, longitude: (segmentDestInfo["lon"] as! NSNumber).doubleValue)
                        var toStop: String? = nil
                        
                        if segmentDestInfo.objectForKey("stop") != nil {
                            toStop = segmentDestInfo["stop"] as? String
                        }
                        
                        var routeType: BusLineType? = nil
                        var tripID: String? = nil
                        
                        if segmentInfo.keys.contains("trip_id") {
                            
                            tripID = segmentInfo["trip_id"] as? String
                            
                            guard let tripInformation = DatabaseManager.sharedInstance.infoForTripIdentifier(tripID!) else {
                                dispatch_async(dispatch_get_main_queue()) {
                                    self.delegate.tripPlannerDidCompleteWithError(self, error: .VersionError)
                                }
                                
                                return
                            }
                            
                            if routes.last == nil || routes.last!.toString != tripInformation.lineType.toString {
                                routes.append(tripInformation.lineType)
                            }
                            
                            routeType = tripInformation.lineType
                            
                        }
                        
                        var polylinePoints: [CLLocationCoordinate2D] = []
                        
                        for point in segment["points"] as! NSArray {
                            let coords = point as! NSArray
                            polylinePoints.append(CLLocationCoordinate2D(latitude: (coords[0] as! NSNumber).doubleValue, longitude: (coords[1] as! NSNumber).doubleValue))
                        }
                        
                        let segmentObject = TripPlannerSegment(isBusJourney: isBusSegment,
                                                               route: routeType, tripID: tripID,
                                                               startTime: segmentStart, endTime: segmentEnd, duration: segmentDuration,
                                                               startPosition: fromPoint, endPosition: toPoint,
                                                               startStop: fromStop, endStop: toStop,
                                                               polylinePoints: polylinePoints)
                        
                        segments.append(segmentObject)
                        
                    }
                    
                    let journeyObject = TripPlannerJourney(startTime: startTime,finishTime: finishTime,
                                                           startLocationString: nil, endLocationString: nil,
                                                           walkTime: walkTime, transitTime: transitTime, duration: duration,
                                                           segments: segments, routes: routes)
                    trips.append(journeyObject)
                    
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.delegate.tripPlannerDidCompleteSuccessfully(self, journey: trips)
                }
                
            } catch _ {
                dispatch_async(dispatch_get_main_queue()) {
                    self.delegate.tripPlannerDidCompleteWithError(self, error: .ParseError)
                }
                return
            }
            
        }
        
    }

}