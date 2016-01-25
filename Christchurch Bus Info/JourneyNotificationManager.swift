//
//  JourneyNotificationManager.swift
//  Bus Assistant
//
//  Created by Jack Greenhill on 18/01/16.
//  Copyright © 2016 Miyazu App + Web Design. All rights reserved.
//

import UIKit

protocol JourneyNotificationManagerDelegate {
    func activeJourneyDidChange(newJourney: TripPlannerJourney?)
}

class JourneyNotificationManager: NSObject {

    static let sharedInstance = JourneyNotificationManager()
    static let archivedJourneyLocation = APPLICATION_SUPPORT_DIRECTORY + "/archived_journey"
    
    private var currentJourney: TripPlannerJourney? = nil
    var delegate: JourneyNotificationManagerDelegate?
    
    var activeJourney: TripPlannerJourney? {
        set {
            if self.currentJourney != nil {
                _ = try? NSFileManager.defaultManager().removeItemAtPath(JourneyNotificationManager.archivedJourneyLocation)
                self.removeNotifications()
            }
            
            self.currentJourney = newValue
            delegate?.activeJourneyDidChange(self.currentJourney)
            
            if newValue != nil {
                NSKeyedArchiver.archiveRootObject(newValue!, toFile: JourneyNotificationManager.archivedJourneyLocation)
                self.scheduleNotifications()
            }
        }
        
        get {
            if currentJourney == nil {
                if NSFileManager.defaultManager().fileExistsAtPath(JourneyNotificationManager.archivedJourneyLocation) {
                    
                    let unarchivedObject = NSKeyedUnarchiver.unarchiveObjectWithFile(JourneyNotificationManager.archivedJourneyLocation) as! TripPlannerJourney
                    self.currentJourney = unarchivedObject
                    
                    return unarchivedObject
                    
                } else {
                    return nil
                }
            } else {
                return self.currentJourney
            }
        }
    }
    
    func removeNotifications() {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
    }
    
    func scheduleNotifications() {
        
        UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert, categories: nil))
        removeNotifications()
        
        for segment in activeJourney!.segments {
            
            if segment.isBusJourney {
                
                let tripInformation = DatabaseManager.sharedInstance.infoForTripIdentifier(segment.tripID!)!
                let endStopInfo = RouteInformationManager.sharedInstance.stopInformation![segment.endStop!]!
                
                //Schedule a notification when it's time to board the bus
                let boardNotification = UILocalNotification()
                
                boardNotification.alertTitle = "Journey Progress"
                boardNotification.alertBody = "Board \(tripInformation.lineName) (\(tripInformation.lineType.toString)) towards \(tripInformation.routeName)"
                boardNotification.fireDate = segment.startTime
                
                UIApplication.sharedApplication().scheduleLocalNotification(boardNotification)
                
                let alightNotification = UILocalNotification()
                
                alightNotification.alertTitle = "Journey Progress"
                alightNotification.alertBody = "Prepare to leave \(tripInformation.lineName) (\(tripInformation.lineType.toString)) at stop \(segment.endStop!), \(endStopInfo.roadName) near \(endStopInfo.name)"
                alightNotification.fireDate = segment.endTime.dateByAddingTimeInterval(-30)
                
                UIApplication.sharedApplication().scheduleLocalNotification(alightNotification)
                
            } else {
                
                let walkNotification = UILocalNotification()
                var walkEndDestination = "destination"
                
                if segment.endStop != nil {
                    let endStopInfo = RouteInformationManager.sharedInstance.stopInformation![segment.endStop!]!
                    walkEndDestination = "stop \(segment.endStop!), \(endStopInfo.roadName) near \(endStopInfo.name)"
                }
                
                walkNotification.alertTitle = "Journey Progress"
                walkNotification.alertBody = "Walk to " + walkEndDestination
                walkNotification.fireDate = segment.startTime
                
                UIApplication.sharedApplication().scheduleLocalNotification(walkNotification)
                
            }
        }
    }
    
}
