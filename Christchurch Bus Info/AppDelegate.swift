//
//  AppDelegate.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 5/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import GoogleMaps

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        NSUserDefaults.standardUserDefaults().registerDefaults(Preferences.defaultPreferences)
        GMSServices.provideAPIKey("AIzaSyBjlI9L_fLK0ezqdoK3ley__Qfyb8zsYdw")
        
        return true
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        
        if application.applicationState == .Active {
            
            let alert = UIAlertController(title: notification.alertAction, message: notification.alertBody, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil))
            
            let controller = application.delegate!.window!!.rootViewController!
            controller.presentViewController(alert, animated: true, completion: nil)
            
        }
        
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String: AnyObject]) -> Bool {
        
        if MKDirectionsRequest.isDirectionsRequestURL(url) {
            
            let directionRequest = MKDirectionsRequest(contentsOfURL: url)
            
            let tabBarController = window?.rootViewController as! UITabBarController
            let plannerNavigationController = tabBarController.viewControllers![2] as! UINavigationController
            
            let plannerController = plannerNavigationController.viewControllers.first as! RoutePlannerViewController
            plannerController.deferredDirectionsRequest = directionRequest
            
            tabBarController.selectedIndex = 2
            
            return true
            
        } else {
            return false
        }
        
    }

}

