//
//  MoreInformationTableViewController.swift
//  Bus Assistant for Christchurch
//
//  Created by Jack Greenhill on 26/01/16.
//  Copyright © 2016 Miyazu App + Web Design. All rights reserved.
//

import UIKit

class CheckUpdateTableViewCell: UITableViewCell {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    let tintColour = UIColor(hex: "#007AFF")
    
    var isEnabled: Bool = true {
        didSet {
            self.userInteractionEnabled = isEnabled
            self.titleLabel.textColor = isEnabled ? self.tintColour : UIColor.lightGrayColor()
        }
    }
    
}

class MoreInformationTableViewController: UITableViewController {

    @IBOutlet var databaseVersionCell: UITableViewCell!
    @IBOutlet var checkForUpdateCell: CheckUpdateTableViewCell!
    
    @IBOutlet var updateAutomaticallySwitch: UISwitch!
    
    static let databaseInformationSection = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func updateAutomaticallySwitchValueChanged(sender: AnyObject?) {
        Preferences.shouldAutomaticallyUpdate = updateAutomaticallySwitch.on
    }
    
    func manuallyUpdateDatabase() {
        
        checkForUpdateCell.isEnabled = false
        checkForUpdateCell.activityIndicator.startAnimating()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            
            if UpdateManager.sharedInstance.isUpdateAvailable {
                
                let updateAvailableActionSheet = UIAlertController(title: "Update Available", message: "A newer version of the database is available to download.", preferredStyle: .ActionSheet)
                
                updateAvailableActionSheet.addAction(UIAlertAction(title: "Download Update", style: .Default, handler: { _ -> Void in
                    UpdateManager.sharedInstance.downloadLatestDatabase(true) { _ -> Void in
                        self.databaseVersionCell.detailTextLabel!.text = UpdateManager.sharedInstance.databaseVersion
                    }
                }))
                
                updateAvailableActionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.presentViewController(updateAvailableActionSheet, animated: true, completion: { _ -> Void in
                        self.checkForUpdateCell.isEnabled = true
                        self.checkForUpdateCell.activityIndicator.stopAnimating()
                    })
                }
                
            } else {
                
                let noUpdateAvailableAlert = UIAlertController(title: "No Update Available", message: "The latest version of the database is currently installed.", preferredStyle: .Alert)
                noUpdateAvailableAlert.addAction(UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil))
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.presentViewController(noUpdateAvailableAlert, animated: true, completion: { _ -> Void in
                        self.checkForUpdateCell.isEnabled = true
                        self.checkForUpdateCell.activityIndicator.stopAnimating()
                    })
                }
                
            }
                
        }
        
    }
    
    func confirmDatabaseReset() {
        
        let confirmationActionSheet = UIAlertController(title: nil, message: "Resetting the database will replace the version currently downloaded with the one originally bundled with the application.", preferredStyle: .ActionSheet)
        
        confirmationActionSheet.addAction(UIAlertAction(title: "Reset Database", style: .Destructive, handler: { _ -> Void in
            UpdateManager.sharedInstance.resetDatabase {
                self.databaseVersionCell.detailTextLabel!.text = UpdateManager.sharedInstance.databaseVersion
            }
        }))
        
        confirmationActionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(confirmationActionSheet, animated: true, completion: nil)
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == MoreInformationTableViewController.databaseInformationSection {
            
            tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow!, animated: true)
            
            if indexPath.row == 2 {
                manuallyUpdateDatabase()
            } else if indexPath.row == 3 {
                confirmDatabaseReset()
            }
            
        }
        
    }

    override func viewWillAppear(animated: Bool) {
        
        databaseVersionCell.detailTextLabel!.text = UpdateManager.sharedInstance.databaseVersion
        updateAutomaticallySwitch.on = Preferences.shouldAutomaticallyUpdate
        
        if tableView.indexPathForSelectedRow != nil {
            tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow!, animated: true)
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            
            if TripPlanner.canAccessServer == false {
                dispatch_async(dispatch_get_main_queue()) {
                    self.checkForUpdateCell.isEnabled = false
                }
            }
            
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
