//
//  TripPlanner.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 12/12/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit
import CoreLocation

extension NSDate {
    func toDateTimeString(twelveHourTime: Bool = false) -> (date: String, time: String) {
        let formatter = NSDateFormatter()
        
        formatter.dateFormat = "YYYY-MM-dd"
        let dateString = formatter.stringFromDate(self)
        
        formatter.dateFormat = twelveHourTime ? "h:mm a" : "HH:mm"
        let timeString = formatter.stringFromDate(self)
        
        return (date: dateString, time: timeString)
    }
    
    static func representationToDate(stringRepresentation: String) -> NSDate {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        
        return formatter.dateFromString(stringRepresentation)!
    }
}

func < (lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.timeIntervalSinceDate(rhs) < 0
}

extension CLLocationCoordinate2D {
    func toCoordinateString() -> String {
        return String(self.latitude) + "," + String(self.longitude)
    }
}

protocol TripPlannerDelegate {
    func tripPlannerDidBegin(planner: TripPlanner)
    func tripPlannerDidCompleteWithError(planner: TripPlanner, error: TripPlannerError)
    func tripPlannerDidCompleteSuccessfully(planner: TripPlanner, journey: [TripPlannerJourney])
}

enum TripPlannerError {
    case VersionError
    case ConnectionError
    case ParseError
}

struct TripPlannerSegment {
    var isBusJourney: Bool
    var route: BusLineType?
    
    var startTime: NSDate
    var endTime: NSDate
    var duration: Int
    
    var startPosition: CLLocationCoordinate2D
    var endPosition: CLLocationCoordinate2D
    
    var startStop: String?
    var endStop: String?
    
    var polylinePoints: [CLLocationCoordinate2D]
}

struct TripPlannerJourney {
    var startTime: NSDate
    var finishTime: NSDate
    
    var walkTime: Int
    var transitTime: Int
    var duration: Int
    
    var segments: [TripPlannerSegment]
    var routes: [BusLineType]
}

class TripPlanner: NSObject {
    
    private var startPosition: CLLocation
    private var endPosition: CLLocation
    
    private var startTime: NSDate
    private var delegate: TripPlannerDelegate
    
    private lazy var requestURL: NSURL = { [unowned self] in
        let (dateString, timeString) = self.startTime.toDateTimeString()
        let (startPosString, endPosString) = (self.startPosition.coordinate.toCoordinateString(), self.endPosition.coordinate.toCoordinateString())

        return NSURL(string: "https://metro.miyazudesign.co.nz/trip_planner.php?from=\(startPosString)&to=\(endPosString)&date=\(dateString)&time=\(timeString)")!
    }()
    
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
                        
                        if segmentInfo.keys.contains("trip_id") {
                            let tripID = segmentInfo["trip_id"] as! String
                            
                            guard let (_, _, type) = DatabaseManager.sharedInstance.infoForTripIdentifier(tripID) else {
                                dispatch_async(dispatch_get_main_queue()) {
                                    self.delegate.tripPlannerDidCompleteWithError(self, error: .VersionError)
                                }
                                return
                            }
                            
                            routes.append(type)
                            routeType = type
                        }
                        
                        var polylinePoints: [CLLocationCoordinate2D] = []
                        
                        for point in segment["points"] as! NSArray {
                            let coords = point as! NSArray
                            polylinePoints.append(CLLocationCoordinate2D(latitude: (coords[0] as! NSNumber).doubleValue, longitude: (coords[1] as! NSNumber).doubleValue))
                        }
                        
                        let segmentObject = TripPlannerSegment(isBusJourney: isBusSegment,
                                                               route: routeType,
                                                               startTime: segmentStart, endTime: segmentEnd, duration: segmentDuration,
                                                               startPosition: fromPoint, endPosition: toPoint,
                                                               startStop: fromStop, endStop: toStop,
                                                               polylinePoints: polylinePoints)
                        
                        segments.append(segmentObject)
                        
                    }
                    
                    let journeyObject = TripPlannerJourney(startTime: startTime, finishTime: finishTime, walkTime: walkTime, transitTime: transitTime, duration: duration, segments: segments, routes: routes)
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