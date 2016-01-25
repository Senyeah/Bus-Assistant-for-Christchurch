//
//  CommonDefinitions.swift
//  Bus Assistant
//
//  Created by Jack Greenhill on 23/01/16.
//  Copyright © 2016 Miyazu App + Web Design. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

typealias RoutePolylineCoordinates = (route: BusLineType, points: [[CLLocationCoordinate2D]])
typealias LineSectionInformation = [(sectionTitle: String, routes: [RouteInformation])]
typealias RouteInformation = (lineType: BusLineType, routeName: String)
typealias TripInformation = (lineType: BusLineType, routeName: String, lineName: String, tripID: String)
typealias ProjectedMapSpan = (horizontalDistance: Double, verticalDistance: Double)

extension CLLocationCoordinate2D: Hashable {
    public var hashValue: Int {
        get {
            return (latitude.hashValue &* 397) &+ longitude.hashValue
        }
    }
    
    public var stringValue: String {
        get {
            return String(self.latitude) + "," + String(self.longitude)
        }
    }
}

public func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}

extension UIColor {
    var hexString: String {
        get {
            let components = CGColorGetComponents(self.CGColor)
            let (r, g, b) = (components[0], components[1], components[2])
            
            return String(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        }
    }
    
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        assert(hex[hex.startIndex] == "#", "Expected hex string of format #RRGGBB")
        
        let scanner = NSScanner(string: hex)
        scanner.scanLocation = 1  // skip #
        
        var rgb: UInt32 = 0
        scanner.scanHexInt(&rgb)
        
        self.init(  red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((rgb & 0xFF00) >> 8) / 255.0,
                   blue: CGFloat((rgb & 0xFF)) / 255.0,
                  alpha: alpha)
    }
}

extension NSDate {
    func toShortDateTimeString(alwaysShowDay: Bool = false) -> String {
        let formatter = NSDateFormatter()
        
        formatter.dateStyle = NSCalendar.currentCalendar().isDateInToday(self) && !alwaysShowDay ? .NoStyle : .MediumStyle
        formatter.timeStyle = .ShortStyle
        
        return formatter.stringFromDate(self)
    }

    func toDateTimeString(twelveHourTime: Bool = false) -> (date: String, time: String) {
        let formatter = NSDateFormatter()
        
        formatter.dateFormat = "YYYY-MM-dd"
        let dateString = formatter.stringFromDate(self)
        
        formatter.dateFormat = twelveHourTime ? "h:mm a" : "HH:mm"
        let timeString = formatter.stringFromDate(self)
        
        return (date: dateString, time: timeString)
    }
    
    public var localisedTimeString: String {
        get {
            let formatter = NSDateFormatter()
            
            formatter.timeStyle = .ShortStyle
            formatter.dateStyle = .NoStyle
            
            return formatter.stringFromDate(self)
        }
    }
    
    class func representationToDate(stringRepresentation: String) -> NSDate {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        
        return formatter.dateFromString(stringRepresentation)!
    }
}

func < (lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.timeIntervalSinceDate(rhs) < 0
}

func > (lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.timeIntervalSinceDate(rhs) > 0
}
