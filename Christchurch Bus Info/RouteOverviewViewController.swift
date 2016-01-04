//
//  RouteOverviewViewController.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 20/12/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit
import MapKit

extension UIColor {
    var hexString: String {
        let components = CGColorGetComponents(self.CGColor)
        let (r, g, b) = (components[0], components[1], components[2])
        
        return String(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
    }
}

class RouteOverviewViewController: UIViewController, MKMapViewDelegate, RouteDetailSegmentInfoDelegate {

    @IBOutlet var detailInformationTopBorderView: UIView!
    @IBOutlet var mapView: MKMapView!
    
    var tripInfo: TripPlannerJourney?
    var prioritisedPolyline: MKPolyline?
    
    var pinOverlays: [MKAnnotation] = []
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation.isKindOfClass(MKUserLocation) == false {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "PinAnnotation")
            
            annotationView.enabled = true
            annotationView.canShowCallout = true
            annotationView.animatesDrop = false
            
            return annotationView
        }
        
        return nil
        
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay.isKindOfClass(MKPolyline) {
        
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            var strokeColour = self.view.tintColor
            
            if overlay.title! != nil {
                strokeColour = UIColor(hex: overlay.title!!)
                polylineRenderer.alpha = self.prioritisedPolyline == nil ? 0.8 : 0.4
            } else {
                polylineRenderer.lineDashPattern = [15, 30]
                polylineRenderer.alpha = self.prioritisedPolyline == nil ? 1.0 : 0.5
            }
            
            polylineRenderer.lineWidth = 9.0
            polylineRenderer.strokeColor = strokeColour
            
            if prioritisedPolyline != nil && polylineRenderer.polyline == prioritisedPolyline! {
                polylineRenderer.alpha = 1.0
            }
        
            return polylineRenderer
            
        } else {
            return MKOverlayRenderer()
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let detailController = (segue.destinationViewController as! UINavigationController).viewControllers.first as! RouteDetailTableViewController
        
        detailController.delegate = self
        detailController.tripInfo = tripInfo!
        
    }
    
    func routeDetailController(controller: RouteDetailTableViewController, didSelectTripInfoSegment segmentOffset: Int) {
        
        var detailPolylineCoordinates = tripInfo!.segments[segmentOffset].polylinePoints

        addInformationPinWithCoordinate(detailPolylineCoordinates.first!, title: "Start", subtitle: nil)
        addInformationPinWithCoordinate(detailPolylineCoordinates.last!, title: "End", subtitle: nil)
        
        prioritisedPolyline = MKPolyline(coordinates: &detailPolylineCoordinates, count: detailPolylineCoordinates.count)
        prioritisedPolyline!.title = tripInfo!.segments[segmentOffset].route?.colours().background!.hexString
        
        mapView.removeOverlays(mapView.overlays)
        layoutPolylines()
        
    }
    
    func addInformationPinWithCoordinate(coordinate: CLLocationCoordinate2D, title: String, subtitle: String?) {
        
        let annotation = MKPointAnnotation()
        
        annotation.title = title
        annotation.subtitle = subtitle
        annotation.coordinate = coordinate
        
        pinOverlays.append(annotation)
        mapView.addAnnotation(annotation)
        
    }
    
    func routeDetailController(controller: RouteDetailTableViewController, didSelectInfoForStartStopOnSegment segmentOffset: Int) {
        
        mapView.removeAnnotations(pinOverlays)
        pinOverlays.removeAll()
        
        let segment = tripInfo!.segments[segmentOffset]
        
        guard let stop = segment.startStop else {
            return
        }
        
        let stopInfo = RouteInformationManager.sharedInstance.stopInformation![stop]!
        addInformationPinWithCoordinate(stopInfo.location.coordinate, title: "\(stopInfo.roadName) near \(stopInfo.name)", subtitle: "Stop \(stopInfo.stopNo)")
        
    }
    
    func routeDetailController(controller: RouteDetailTableViewController, didSelectInfoForEndStopOnSegment segmentOffset: Int) {
        
        mapView.removeAnnotations(pinOverlays)
        pinOverlays.removeAll()
        
        let segment = tripInfo!.segments[segmentOffset]
        
        guard let stop = segment.endStop else {
            return
        }
        
        let stopInfo = RouteInformationManager.sharedInstance.stopInformation![stop]!
        addInformationPinWithCoordinate(stopInfo.location.coordinate, title: "\(stopInfo.roadName) near \(stopInfo.name)", subtitle: "Stop \(stopInfo.stopNo)")
        
    }
    
    func layoutPolylines() {
        
        guard let tripSegments = tripInfo?.segments else {
            return
        }
        
        var cumulativeCoordinates: [CLLocationCoordinate2D] = []
        
        var walkingPolylines: [MKPolyline] = []
        var busRoutePolylines: [MKPolyline] = []
        
        for segment in tripSegments {
            
            var coordinatePoints = segment.polylinePoints
            let polyline = MKPolyline(coordinates: &coordinatePoints, count: coordinatePoints.count)
            
            polyline.title = segment.route?.colours().background!.hexString
            
            if segment.route == nil {
                walkingPolylines.append(polyline)
            } else {
                busRoutePolylines.append(polyline)
            }
            
            cumulativeCoordinates.appendContentsOf(coordinatePoints)
            
        }
        
        for polyline in busRoutePolylines {
            mapView.addOverlay(polyline, level: .AboveRoads)
        }
        
        //Walking instructions need to be above everything else
        
        for polyline in walkingPolylines {
            mapView.addOverlay(polyline, level: .AboveRoads)
        }
        
        if prioritisedPolyline != nil {
            mapView.addOverlay(prioritisedPolyline!, level: .AboveRoads)
        }
        
        let tripPolyline = MKPolyline(coordinates: &cumulativeCoordinates, count: cumulativeCoordinates.count)
        
        //I have no idea why I need to do this
        dispatch_async(dispatch_get_main_queue()) {
            if self.prioritisedPolyline != nil {
                self.mapView.setVisibleMapRect(self.prioritisedPolyline!.boundingMapRect, edgePadding: UIEdgeInsetsMake(20.0, 20.0, 120.0, 20.0), animated: false)
            } else {
                self.mapView.setVisibleMapRect(tripPolyline.boundingMapRect, edgePadding: UIEdgeInsetsMake(20.0, 20.0, 120.0, 20.0), animated: false)
            }
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutPolylines()
    }
    
}
