//
//  RouteOverviewViewController.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 20/12/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit
import MapKit

class RouteOverviewViewController: UIViewController, MKMapViewDelegate, RouteDetailSegmentInfoDelegate {

    @IBOutlet var detailInformationView: UIView!
    @IBOutlet var mapView: MKMapView!
    
    @IBOutlet var tripSegmentsView: TripSegmentVisualisationView!
    @IBOutlet var tripDurationLabel: UILabel!
    
    var notificationsEnabled: Bool = false
    
    var tripInfo: TripPlannerJourney?
    var prioritisedPolyline: MKPolyline?
    
    var pinAnnotations: [MKAnnotation] = []
    var visibleAnnotations: [CLLocationCoordinate2D: MKAnnotation] = [:]
    
    func layoutLegalAttributionLabel() {
        
        let attributionLabel = mapView.subviews[1]
        let calculated = self.view.frame.height - detailInformationView.frame.height - 64.0

        attributionLabel.center = CGPointMake(attributionLabel.center.x, calculated)
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        notificationsEnabled = false
    }
    
    override func viewDidAppear(animated: Bool) {
        layoutLegalAttributionLabel()
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        layoutLegalAttributionLabel()
        layoutPolylines()
        
        if let segmentRoutes = tripInfo?.routes {
            tripSegmentsView.routes = segmentRoutes
        }
        
        if let tripDuration = tripInfo?.duration {
            tripDurationLabel.text = formattedTimeStringForDuration(tripDuration)
        }
        
        let borderLayer = CALayer()
        
        borderLayer.frame = CGRectMake(0.0, 0.0, detailInformationView.frame.width, 1.0 / UIScreen.mainScreen().scale)
        borderLayer.backgroundColor = UIColor(hex: "#a8acac").CGColor
        
        detailInformationView.layer.addSublayer(borderLayer)
        
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            
            let zoomLevel = mapView.visibleMapRect.size.width / Double(mapView.bounds.size.width)
            
            if zoomLevel > BusStopAnnotationController.ROUTE_PLANNER_STOP_ZOOM_LEVEL {
                
                for (_, annotation) in self.visibleAnnotations {
                    dispatch_async(dispatch_get_main_queue()) {
                        mapView.removeAnnotation(annotation)
                    }
                }
                
                self.visibleAnnotations.removeAll()
                return
                
            }
            
            let annotationsToDisplay = BusStopAnnotationController.annotationsForRegion(self.mapView.visibleMapRect).filter { annotation in
                return self.visibleAnnotations.keys.contains(annotation.coordinate) == false
            }
            
            for (coordinate, annotation) in self.visibleAnnotations {
                
                if MKMapRectContainsPoint(mapView.visibleMapRect, MKMapPointForCoordinate(coordinate)) == false {
                    self.visibleAnnotations.removeValueForKey(coordinate)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        mapView.removeAnnotation(annotation)
                    }
                }
                
            }
            
            for annotation in annotationsToDisplay {
                self.visibleAnnotations[annotation.coordinate] = annotation
                
                dispatch_async(dispatch_get_main_queue()) {
                    mapView.addAnnotation(annotation)
                }
            }
        }
        
    }
    
    @IBAction func notifyMeButtonPressed(sender: AnyObject?) {
        
        let notificationMessage: String? = !notificationsEnabled ? "Enabling notifications will alert you of actions you need to take as this journey progresses." : nil
        let actionSheet = UIAlertController(title: nil, message: notificationMessage, preferredStyle: .ActionSheet)
        
        if notificationsEnabled {
            actionSheet.addAction(UIAlertAction(title: "Disable Notifications", style: .Default) { _ -> Void in
                JourneyNotificationManager.sharedInstance.removeNotifications()
                JourneyNotificationManager.sharedInstance.activeJourney = nil
                self.notificationsEnabled = false
            })
        } else {
            actionSheet.addAction(UIAlertAction(title: "Enable Notifications", style: .Default) { _ -> Void in
                JourneyNotificationManager.sharedInstance.activeJourney = self.tripInfo!
                self.notificationsEnabled = true
            })
        }
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        self.presentViewController(actionSheet, animated: true, completion: nil)
        
    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation.isKindOfClass(BusStopAnnotation) {
            
            let view = BusStopAnnotationView(annotation: annotation, reuseIdentifier: "BusStopLocationPin")
            view.canShowCallout = true
            
            return view
            
        } else if annotation.isKindOfClass(MKUserLocation) == false {
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
                polylineRenderer.lineDashPattern = [20, 13]
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
        
        mapView.removeAnnotations(pinAnnotations)
        pinAnnotations.removeAll()
        
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
        
        pinAnnotations.append(annotation)
        mapView.addAnnotation(annotation)
        
    }
    
    func routeDetailController(controller: RouteDetailTableViewController, didSelectInfoForStartStopOnSegment segmentOffset: Int) {
        
        mapView.removeAnnotations(pinAnnotations)
        pinAnnotations.removeAll()
        
        let segment = tripInfo!.segments[segmentOffset]
        
        if let stop = segment.endStop {
            
            let stopInfo = RouteInformationManager.sharedInstance.stopInformation![stop]!
            
            addInformationPinWithCoordinate(stopInfo.location.coordinate, title: "\(stopInfo.roadName) near \(stopInfo.name)", subtitle: "Stop \(stopInfo.stopNo)")
            zoomIntoCoordinatePin(stopInfo.location.coordinate)
            
        } else {
            addInformationPinWithCoordinate(segment.endPosition, title: "Start", subtitle: nil)
            zoomIntoCoordinatePin(segment.endPosition)
        }
        
    }
    
    func routeDetailController(controller: RouteDetailTableViewController, didSelectInfoForEndStopOnSegment segmentOffset: Int) {
        
        mapView.removeAnnotations(pinAnnotations)
        pinAnnotations.removeAll()
        
        let segment = tripInfo!.segments[segmentOffset]
        
        if let stop = segment.endStop {
            
            let stopInfo = RouteInformationManager.sharedInstance.stopInformation![stop]!
            
            addInformationPinWithCoordinate(stopInfo.location.coordinate, title: "\(stopInfo.roadName) near \(stopInfo.name)", subtitle: "Stop \(stopInfo.stopNo)")
            zoomIntoCoordinatePin(stopInfo.location.coordinate)
            
        } else {
            addInformationPinWithCoordinate(segment.endPosition, title: "Destination", subtitle: nil)
            zoomIntoCoordinatePin(segment.endPosition)
        }
        
    }
    
    func zoomIntoCoordinatePin(location: CLLocationCoordinate2D) {
        let coordinateRegion = MKCoordinateRegionMake(location, MKCoordinateSpanMake(0.005, 0.005))
        mapView.setRegion(coordinateRegion, animated: true)
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
    
}
