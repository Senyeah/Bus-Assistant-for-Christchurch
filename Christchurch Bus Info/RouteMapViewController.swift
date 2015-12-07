//
//  RouteMapViewController.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 26/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class RouteMapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet var mapView: MKMapView!

    var polylineColour: UIColor!
    var polylineCoordinates: [CLLocationCoordinate2D] = []
    

        
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        mapView.delegate = self
        
        let polyline = MKPolyline(coordinates: &polylineCoordinates, count: polylineCoordinates.count)
        mapView.addOverlay(polyline, level: .AboveRoads)
        
//        mapView.setVisibleMapRect(polyline.boundingMapRect, edgePadding: UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0), animated: false)
        
        mapView.setRegion(mapView.regionThatFits(MKCoordinateRegionForMapRect(polyline.boundingMapRect)), animated: false)
        
    }

}
