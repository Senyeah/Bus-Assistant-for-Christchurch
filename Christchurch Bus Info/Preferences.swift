//
//  Preferences.swift
//  Bus Assistant for Christchurch
//
//  Created by Jack Greenhill on 27/01/16.
//  Copyright © 2016 Miyazu App + Web Design. All rights reserved.
//

import UIKit

struct Preferences {
    
    static var shouldAutomaticallyUpdate: Bool {
        get {
            if NSUserDefaults.standardUserDefaults().objectForKey("shouldAutomaticallyUpdate") == nil {
                return Preferences.defaultPreferences["shouldAutomaticallyUpdate"] as! Bool
            }
        
            return NSUserDefaults.standardUserDefaults().boolForKey("shouldAutomaticallyUpdate")
        }
        
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: "shouldAutomaticallyUpdate")
        }
    }
    
    static var mapRoutes: [BusLineType] {
        get {
            return (NSUserDefaults.standardUserDefaults().objectForKey("mapRoutes") as! [String]).map { routeString in
                return BusLineType(lineAbbreviationString: routeString)
            }
        }
        
        set {
            let routePreferences = newValue.map { route in
                return route.toString
            }
            
            NSUserDefaults.standardUserDefaults().setObject(routePreferences, forKey: "mapRoutes")
        }
    }
    
    static var favouriteStops: [StopInformation] {
        get {
            let savedFavourites = (NSUserDefaults.standardUserDefaults().objectForKey("favouriteStops") ?? defaultPreferences["favouriteStops"]) as! [String]
            
            return savedFavourites.map { stopNumber in
                if let information = RouteInformationManager.sharedInstance.stopInformationForStopNumber(stopNumber) {
                    return information
                }
                
                fatalError("info for \(stopNumber) is nil?!")
            }
        }
        
        set {
            let favouriteStops = newValue.map { stop in
                return stop.stopNo
            }

            NSUserDefaults.standardUserDefaults().setObject(favouriteStops, forKey: "favouriteStops")
        }
    }
    
    static var defaultPreferences: [String: AnyObject] {
        get {
            let routes: [BusLineType] = [.PurpleLine, .OrangeLine, .YellowLine, .BlueLine, .Orbiter(.Clockwise)]
            let routePreferences = routes.map { route in
                return route.toString
            }
            
            return ["shouldAutomaticallyUpdate": true, "mapRoutes": routePreferences, "favouriteStops": []]
        }
    }
    
}