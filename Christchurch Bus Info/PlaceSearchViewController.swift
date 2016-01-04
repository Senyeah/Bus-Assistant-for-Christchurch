//
//  PlaceSearchViewController.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 16/12/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import GoogleMaps

protocol PlaceSearchResultDelegate {
    var rowAffected: Int { get set }
    var routePlannerController: RoutePlannerViewController? { get set }
    
    func locationWasChosenWithName(name: String, coordinate: CLLocationCoordinate2D)
}

class PlaceSearchViewController: UIViewController, GMSAutocompleteResultsViewControllerDelegate, MKMapViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet var searchBarView: UIView!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var doneBarButton: UIBarButtonItem!
    
    var pinGestureRecogniser: UILongPressGestureRecognizer?
    var searchResultsController: UISearchController!
    
    let placesAutocompleteController = GMSAutocompleteResultsViewController()
    let geocoder = CLGeocoder()
    
    let initialRegion = MKCoordinateRegion(center: CLLocationCoordinate2DMake(-43.5308976282826, 172.631358772907), span: MKCoordinateSpanMake(0.266642872868438, 0.255848180836665))
    
    var locationPinVisibleOnMap = false
    var locationPinName: String?
    
    var locationPinAnnotation: MKPointAnnotation? {
        didSet {
            if locationPinAnnotation != nil {
                doneBarButton.enabled = true
            }
        }
    }
    
    var delegate: PlaceSearchResultDelegate?
    
    @IBAction func dismissButtonPressed(sender: AnyObject?) {
        let pinStringRepresentation = locationPinName ?? locationPinAnnotation!.coordinate.stringValue
        delegate?.locationWasChosenWithName(pinStringRepresentation, coordinate: locationPinAnnotation!.coordinate)
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancelButtonPressed(sender: AnyObject?) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func reverseGeocodeCoordinate(coordinate: CLLocationCoordinate2D, completion: String? -> ()) {
        
        geocoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) { results, error in
            if results != nil && results?.count > 0 {
                let resultAddress = results!.last!
                
                if resultAddress.subThoroughfare != nil && resultAddress.thoroughfare != nil {
                    completion("\(resultAddress.subThoroughfare!) \(resultAddress.thoroughfare!)")
                } else {
                    completion(resultAddress.thoroughfare)
                }
            } else {
                completion(nil)
            }
        }
        
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKindOfClass(MKPointAnnotation) {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "SelectedLocationPin")
            
            annotationView.draggable = true
            annotationView.animatesDrop = true
            annotationView.canShowCallout = true
            
            return annotationView
        }
        
        return nil
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        let annotationView = view.annotation as! MKPointAnnotation
        
        if newState == .Dragging {
            
            annotationView.title = nil
            
        } else if newState == .Ending {
            
            reverseGeocodeCoordinate(annotationView.coordinate) { displayString in
                annotationView.title = displayString
                self.locationPinName = displayString
                
                mapView.selectAnnotation(annotationView, animated: true)
            }
            
        }
    }
    
    func resultsController(resultsController: GMSAutocompleteResultsViewController!, didFailAutocompleteWithError error: NSError!) {
        
    }
    
    func resultsController(resultsController: GMSAutocompleteResultsViewController!, didAutocompleteWithPlace place: GMSPlace!) {
        
        if self.locationPinVisibleOnMap == true {
            self.mapView.removeAnnotation(self.locationPinAnnotation!)
        }
    
        searchResultsController.dismissViewControllerAnimated(true) {
            
            let region = MKCoordinateRegionMake(place.coordinate, MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015))
            self.mapView.setRegion(region, animated: true)
            
            self.locationPinAnnotation = MKPointAnnotation()
            
            self.locationPinAnnotation!.coordinate = place.coordinate
            self.locationPinAnnotation!.title = place.name
            
            self.locationPinName = place.name
            
            self.mapView.addAnnotation(self.locationPinAnnotation!)
            self.mapView.selectAnnotation(self.locationPinAnnotation!, animated: true)
            
        }
        
    }
    
    func longPressWasReceived(recognizer: UIGestureRecognizer) {
        
        if recognizer.state == .Began {
            
            if self.locationPinAnnotation != nil {
                self.mapView.removeAnnotation(self.locationPinAnnotation!)
            }
            
            let touchPoint = recognizer.locationInView(mapView)
            let touchCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            
            reverseGeocodeCoordinate(touchCoordinates) { displayString in
                self.locationPinAnnotation = MKPointAnnotation()
                
                self.locationPinAnnotation!.coordinate = touchCoordinates
                self.locationPinAnnotation!.title = displayString
                
                self.locationPinName = displayString
                
                self.mapView.addAnnotation(self.locationPinAnnotation!)
                self.locationPinVisibleOnMap = true
                
                self.mapView.selectAnnotation(self.locationPinAnnotation!, animated: true)
            }
        }
        
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        pinGestureRecogniser = UILongPressGestureRecognizer(target: self, action: "longPressWasReceived:")
        pinGestureRecogniser?.minimumPressDuration = 0.7
        
        mapView.addGestureRecognizer(pinGestureRecogniser!)
        
        mapView.setRegion(initialRegion, animated: false)
        
        searchResultsController = UISearchController(searchResultsController: placesAutocompleteController)
        searchResultsController.dimsBackgroundDuringPresentation = true
        
        placesAutocompleteController.delegate = self

        placesAutocompleteController.edgesForExtendedLayout = .None
        placesAutocompleteController.autocompleteBounds = GMSCoordinateBounds(coordinate: CLLocationCoordinate2DMake(-43.253614, 172.190226), coordinate: CLLocationCoordinate2DMake(-43.683081, 172.806597))
        
        let locationFilter = GMSAutocompleteFilter()
        locationFilter.country = "NZ"
        
        placesAutocompleteController.autocompleteFilter = locationFilter
        
        searchResultsController.searchResultsUpdater = placesAutocompleteController
        searchResultsController.searchBar.placeholder = "Search for address or place"
        
        searchBarView.addSubview(searchResultsController.searchBar)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        searchResultsController.view.removeFromSuperview()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}