//
//  RootTabBarController.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 24/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

class RootTabBarController: UITabBarController {
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let routeInformationManager = sender as! RouteInformationManager
        routeInformationManager.progressViewController = segue.destinationViewController as? DownloadUpdateViewController
    }
    
}
