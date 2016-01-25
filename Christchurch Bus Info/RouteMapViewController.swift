//
//  RouteMapViewController.swift
//  Bus Assistant
//
//  Created by Jack Greenhill on 17/01/16.
//  Copyright © 2016 Miyazu App + Web Design. All rights reserved.
//

import UIKit
import MapKit

class RouteMapViewController: UIViewController, MKMapViewDelegate, RouteMapFilterUpdateDelegate {

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var detailInformationView: UIView!    
    @IBOutlet var routesDisplayedInfoLabel: UILabel!
    
    var visibleAnnotations: [CLLocationCoordinate2D: MKAnnotation] = [:]
    
    var overlays: [MKOverlay] = []
    var routesToDisplay: [BusLineType] = [] {
        didSet {
            //account for there being 2 orbiters
            let totalNumberOfRoutes = DatabaseManager.sharedInstance.allRoutes!.count - 1
            routesDisplayedInfoLabel.text = "\(routesToDisplay.count) of \(totalNumberOfRoutes) routes"
        }
    }
    
    func selectedRoutesDidChange(routes: [BusLineType]) {
        
        dispatch_async(dispatch_get_main_queue()) {
            self.routesToDisplay = routes
            
            self.mapView.removeOverlays(self.overlays)
            self.overlays.removeAll()
            
            self.processRoutePolylines()
        }
        
    }
    
    func selectedRoutes() -> [BusLineType] {
        return routesToDisplay
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        mapView.layoutMargins = UIEdgeInsetsMake(mapView.layoutMargins.top, mapView.layoutMargins.left, -70.0, mapView.layoutMargins.right)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            
            let zoomLevel = mapView.visibleMapRect.size.width / Double(mapView.bounds.size.width)
            
            if zoomLevel > BusStopAnnotationController.MIN_ZOOM_LEVEL_FOR_STOPS {
                
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
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation.isKindOfClass(BusStopAnnotation) {
            
            let view = BusStopAnnotationView(annotation: annotation, reuseIdentifier: "BusStopLocationPin")
            view.canShowCallout = true
            
            if view.rightCalloutAccessoryView == nil {
                view.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            }
            
            return view
            
        }
        
        return nil
        
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        self.performSegueWithIdentifier("StopInfoPressedSegue", sender: view)
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        let colourRepresentation = UIColor(hex: overlay.title!!)
        
        polylineRenderer.strokeColor = colourRepresentation
        polylineRenderer.lineWidth = 8.0
        polylineRenderer.alpha = 1.0
        
        return polylineRenderer
        
    }
    
    func processRoutePolylines() {
        
        guard let polylineCoordinatesForRoutes = DatabaseManager.sharedInstance.coordinatesForRoutes(routesToDisplay) else {
            return
        }
        
        for (route, directionCoordinates) in polylineCoordinatesForRoutes {
            
            for coordinate in directionCoordinates {
                var polylinePoints = coordinate
                let polyline = MKPolyline(coordinates: &polylinePoints, count: polylinePoints.count)
                
                polyline.title = (route.colours().background ?? mapView.tintColor)?.hexString
                
                mapView.addOverlay(polyline, level: .AboveRoads)
                overlays.append(polyline)
            }
            
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if sender != nil && sender!.isKindOfClass(BusStopAnnotationView) {
            
            let destinationViewController = segue.destinationViewController as! StopInformationTableViewController
            
            let selectedAnnotationView = sender as! BusStopAnnotationView
            let selectedAnnotation = selectedAnnotationView.annotation as! BusStopAnnotation
            
            destinationViewController.stopNumber = selectedAnnotation.stop.stopNo
            
        } else {
            let destinationViewController = segue.destinationViewController as! RouteMapLineFilterTableViewController
            destinationViewController.delegate = self
        }

    }
    
    func layoutLegalAttributionLabel() {
        
        let attributionLabel = mapView.subviews[1]
        let calculated = self.view.frame.height - detailInformationView.frame.height - 64.0
        
        attributionLabel.center = CGPointMake(attributionLabel.center.x, calculated)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        layoutLegalAttributionLabel()
    }
    
    override func viewDidLoad() {

        super.viewDidLoad()
        layoutLegalAttributionLabel()
        
        routesToDisplay = [.PurpleLine, .OrangeLine, .YellowLine, .BlueLine, .Orbiter(.Clockwise)]
        
        dispatch_async(dispatch_get_main_queue()) {
            self.processRoutePolylines()
            self.mapView.setRegion(INITIAL_REGION, animated: false)
        }
        
        let borderLayer = CALayer()
        
        borderLayer.frame = CGRectMake(0.0, 0.0, detailInformationView.frame.width, 1.0 / UIScreen.mainScreen().scale)
        borderLayer.backgroundColor = UIColor(hex: "#a8acac").CGColor
        
        detailInformationView.layer.addSublayer(borderLayer)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
