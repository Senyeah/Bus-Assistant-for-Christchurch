//
//  UpdateManager.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 24/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

let UPDATE_URL = "https://metro.miyazudesign.co.nz/latest.php"
let VERSION_URL = "https://metro.miyazudesign.co.nz/version.php"

protocol UpdateManagerDelegate {
    func updateManagerWillDownloadFile(manager: UpdateManager, displayModalController: Bool)
    func updateManagerIsDownloadingFileWithProgress(manager: UpdateManager, progress: Double, currentSize: Int64, maxSize: Int64)
    func updateManagerDidCompleteDownload(manager: UpdateManager, error: NSError?)
    func updateManagerWillExtractUpdate(manager: UpdateManager)
    func updateManagerDidExtractUpdate(manager: UpdateManager, extractionFailed: Bool)
    func updateManagerDidCancelUpdate(manager: UpdateManager)
}

class UpdateManager: NSObject, SSZipArchiveDelegate, NSURLSessionDownloadDelegate, DownloadUpdateViewControllerDelegate {
    
    static let sharedInstance = UpdateManager()
    
    static let downloadedArchiveLocation = APPLICATION_SUPPORT_DIRECTORY + "/database.zip"
    static let zipFolderExpandedPath = APPLICATION_SUPPORT_DIRECTORY + "/database"
    
    var delegate: UpdateManagerDelegate?
    
    var updateDownloadTask: NSURLSessionDownloadTask?
    var updateCompletionHandlers: [() -> Void] = []
    
    var isUpdateAvailable: Bool {
        get {
            guard let latestVersionData = NSData(contentsOfURL: NSURL(string: VERSION_URL)!) else {
                return false
            }
            
            let latestVersion = NSString(data: latestVersionData, encoding: NSUTF8StringEncoding)!
            return !latestVersion.isEqualToString(self.databaseVersion)
        }
    }
    
    var hasCopiedBundledDatabase: Bool {
        get {
            return NSFileManager.defaultManager().fileExistsAtPath(DatabaseManager.databasePath)
        }
    }
    
    var databaseVersion: String {
        get {
            return NSUserDefaults.standardUserDefaults().objectForKey("database_version") as! String
        }
        
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "database_version")
        }
    }
    
    func resetDatabase(completion: (() -> Void)?) {
        
        DatabaseManager.sharedInstance.disconnect()
        removeTemporaryFiles()
        
        _ = try? NSFileManager.defaultManager().removeItemAtPath(DatabaseManager.databasePath)
        
        copyBundledDatabase()
        
        if let completionHandler = completion {
            completionHandler()
        }
        
    }
    
    func currentlyDownloadingUpdateShouldCancel() {
        updateDownloadTask!.cancel()
        delegate?.updateManagerDidCancelUpdate(self)
    }

    func downloadLatestDatabase(displayModalProgressView: Bool = false, completion: (() -> Void)?) {
        
        delegate?.updateManagerWillDownloadFile(self, displayModalController: displayModalProgressView)
        
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        
        updateDownloadTask = session.downloadTaskWithURL(NSURL(string: UPDATE_URL)!)
        updateDownloadTask!.resume()
        
        if let completionHandler = completion {
            updateCompletionHandlers.append(completionHandler)
        }
        
    }
    
    func copyBundledDatabase() {

        let bundledDatabasePath = NSBundle.mainBundle().pathForResource("database", ofType: "zip")!
        
        //make sure the application support directory exists
        
        if NSFileManager.defaultManager().fileExistsAtPath(APPLICATION_SUPPORT_DIRECTORY) == false {
            try! NSFileManager.defaultManager().createDirectoryAtPath(APPLICATION_SUPPORT_DIRECTORY, withIntermediateDirectories: true, attributes: nil)
        }
        
        _ = try? NSFileManager.defaultManager().copyItemAtPath(bundledDatabasePath, toPath: UpdateManager.downloadedArchiveLocation)
        
        extractDatabase()
        
    }
    
    func removeTemporaryFiles() {
        
        for temporaryFile in [UpdateManager.downloadedArchiveLocation, UpdateManager.zipFolderExpandedPath] {
            if NSFileManager.defaultManager().fileExistsAtPath(temporaryFile) {
                _ = try? NSFileManager.defaultManager().removeItemAtPath(temporaryFile)
            }
        }
        
    }
    
    func initialise(runQueue: dispatch_queue_t = dispatch_get_main_queue()) {
        
        self.removeTemporaryFiles()
        
        if self.hasCopiedBundledDatabase == false {
            copyBundledDatabase()
            return
        }
        
        DatabaseManager.sharedInstance.connect()
        DatabaseManager.sharedInstance.parseDatabase()
        
        dispatch_async(dispatch_get_main_queue()) {
            
            for handler in self.updateCompletionHandlers {
                handler()
            }
            
            self.updateCompletionHandlers.removeAll()
            
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { _ -> Void in            
            if Preferences.shouldAutomaticallyUpdate && self.isUpdateAvailable {
                self.downloadLatestDatabase(completion: nil)
            }
        }
        
    }
    
    func initialiseDatabase(runQueue: dispatch_queue_t = dispatch_get_main_queue()) {
        
        //Find the file and get the version number from its filename
        
        let expandedDatabaseDirectory = try! NSFileManager.defaultManager().contentsOfDirectoryAtPath(UpdateManager.zipFolderExpandedPath)
        var expandedDatabasePath: String?
        
        for file in expandedDatabaseDirectory {
            
            if file.hasSuffix("sqlite3") {
                expandedDatabasePath = UpdateManager.zipFolderExpandedPath + "/" + file
                
                var expandedDatabaseVersion = file.stringByReplacingOccurrencesOfString("database-", withString: "")
                expandedDatabaseVersion = expandedDatabaseVersion.stringByReplacingOccurrencesOfString(".sqlite3", withString: "")
                
                self.databaseVersion = expandedDatabaseVersion
                break
            }
            
        }
        
        guard expandedDatabasePath != nil else {
            fatalError("Downloaded file doesn't contain a valid database version")
        }
        
        if NSFileManager.defaultManager().fileExistsAtPath(DatabaseManager.databasePath) {
            DatabaseManager.sharedInstance.disconnect()
            try! NSFileManager.defaultManager().removeItemAtPath(DatabaseManager.databasePath)
        }
        
        try! NSFileManager.defaultManager().moveItemAtPath(expandedDatabasePath!, toPath: DatabaseManager.databasePath)
        
        self.removeTemporaryFiles()
        initialise(runQueue)
        
    }
    
    
    func zipArchiveDidUnzipArchiveAtPath(path: String!, zipInfo: unz_global_info, unzippedPath: String!) {
        delegate?.updateManagerDidExtractUpdate(self, extractionFailed: false)
        
        let backgroundThread = dispatch_queue_create("update_init_thread", nil)
        initialiseDatabase(backgroundThread)
    }
    
    func extractDatabase() {
        
        delegate?.updateManagerWillExtractUpdate(self)
        
        let extractionResult = SSZipArchive.unzipFileAtPath(UpdateManager.downloadedArchiveLocation, toDestination: UpdateManager.zipFolderExpandedPath, delegate: self)
        
        if extractionResult == false {
            delegate?.updateManagerDidExtractUpdate(self, extractionFailed: true)
        }
        
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        
        delegate?.updateManagerDidCompleteDownload(self, error: nil)
        
        //Move it from the temporary location
        let destinationURL = NSURL(fileURLWithPath: UpdateManager.downloadedArchiveLocation)
        
        do {
            try NSFileManager.defaultManager().moveItemAtURL(location, toURL: destinationURL)
        } catch {
            delegate?.updateManagerDidExtractUpdate(self, extractionFailed: true)
        }
        
        extractDatabase()
        
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        delegate?.updateManagerDidCompleteDownload(self, error: error)
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        delegate?.updateManagerIsDownloadingFileWithProgress(self, progress: progress, currentSize: totalBytesWritten, maxSize: totalBytesExpectedToWrite)
    }
    
    override init() {
        super.init()
    }
    
}
