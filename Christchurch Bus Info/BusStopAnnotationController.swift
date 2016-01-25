//
//  BusStopAnnotationController.swift
//  Bus Assistant
//
//  Created by Jack Greenhill on 22/01/16.
//  Copyright © 2016 Miyazu App + Web Design. All rights reserved.
//

import UIKit
import MapKit

class BusStopAnnotation: NSObject, MKAnnotation {
    
    var stop: StopInformation
    var coordinate: CLLocationCoordinate2D {
        get {
            return stop.location.coordinate
        }
    }
    
    var title: String? {
        get {
            return RouteInformationManager.sharedInstance.displayStringForStopNumber(stop.stopNo)
        }
    }
    
    var subtitle: String? {
        get {
            return "Stop \(stop.stopNo)"
        }
    }
    
    init(stop: StopInformation) {
        self.stop = stop
    }
    
}

class BusStopAnnotationView: MKAnnotationView {
    
    var drawRadius: CGFloat = CGFloat(8.0)
    
    override func drawRect(frame: CGRect) {
        
        let context = UIGraphicsGetCurrentContext()
        let shadowColour = UIColor(colorLiteralRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.5)
        
        CGContextSetShadowWithColor(context, CGSizeMake(0.0, 2.0), 3.0, shadowColour.CGColor)
        
        CGContextSetFillColorWithColor(context, self.tintColor.CGColor)
        CGContextFillEllipseInRect(context, CGRectMake(drawRadius / 2.0, 0.0, drawRadius, drawRadius))
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        self.frame = CGRectMake(0.0, 0.0, drawRadius * 2.0, drawRadius * 2.0)
        self.opaque = false
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

class BusStopAnnotationController: NSObject, MKMapViewDelegate {

    static let MIN_ZOOM_LEVEL_FOR_STOPS = 100.0
    
    class func annotationsForRegion(region: MKMapRect) -> [BusStopAnnotation] {
        return RouteInformationManager.sharedInstance.stopsInRegion(region).map { stop in
            return BusStopAnnotation(stop: stop)
        }
    }
    
}
