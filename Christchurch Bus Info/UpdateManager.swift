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
    func updateManagerWillDownloadFile(manager: UpdateManager)
    func updateManagerIsDownloadingFileWithProgress(manager: UpdateManager, progress: Double, currentSize: Int64, maxSize: Int64)
    func updateManagerDidCompleteDownload(manager: UpdateManager, error: NSError?)
    func updateManagerWillExtractUpdate(manager: UpdateManager)
    func updateManagerDidExtractUpdate(manager: UpdateManager, extractionFailed: Bool)
}

class UpdateManager: NSObject, SSZipArchiveDelegate, NSURLSessionDownloadDelegate {
    
    static let sharedInstance = UpdateManager()
    
    static let downloadedArchiveLocation = DOCUMENTS_DIRECTORY + "/database.zip"
    static let zipFolderExpandedPath = DOCUMENTS_DIRECTORY + "/database"
    
    var delegate: UpdateManagerDelegate?
    
    func updateAvailable() -> Bool {
        
        guard let latestVersionData = NSData(contentsOfURL: NSURL(string: VERSION_URL)!) else {
            return false
        }
        
        let latestVersion = NSString(data: latestVersionData, encoding: NSUTF8StringEncoding)!
        let currentVersion = NSUserDefaults.standardUserDefaults().objectForKey("database_version")
        
        return !latestVersion.isEqualToString(currentVersion as! String)
        
    }
    
    func hasCopiedBundledDatabase() -> Bool {
        
        let fileManager = NSFileManager.init()
        return fileManager.fileExistsAtPath(DatabaseManager.databasePath)
        
    }
    
    func setDatabaseVersion(newVersion: String) {
        NSUserDefaults.standardUserDefaults().setObject(newVersion, forKey: "database_version")
    }
    
    func downloadLatestDatabase() {
        
        delegate?.updateManagerWillDownloadFile(self)
        
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        
        let downloadTask = session.downloadTaskWithURL(NSURL(string: UPDATE_URL)!)
        downloadTask.resume()
        
    }
    
    func copyBundledDatabase() {
        
        let fileManager = NSFileManager.init()
        
        let bundledDatabasePath = NSBundle.mainBundle().pathForResource("database", ofType: "zip")!
        _ = try? fileManager.copyItemAtPath(bundledDatabasePath, toPath: UpdateManager.downloadedArchiveLocation)
        
        extractDatabase()
        
    }
    
    func removeTemporaryFiles() {
        
        //The shared manager is not thread safe
        
        let fileManager = NSFileManager.init()
        
        for temporaryFile in [UpdateManager.downloadedArchiveLocation, UpdateManager.zipFolderExpandedPath] {
            if fileManager.fileExistsAtPath(temporaryFile) {
                _ = try? fileManager.removeItemAtPath(temporaryFile)
            }
            
        }
        
    }
    
    func initialise(runQueue: dispatch_queue_t = dispatch_get_main_queue()) {
        
        self.removeTemporaryFiles()
        
        if hasCopiedBundledDatabase() == false {
            copyBundledDatabase()
            return
        }
        
        DatabaseManager.sharedInstance.connect()
        DatabaseManager.sharedInstance.parseDatabase()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            if self.updateAvailable() {
                self.downloadLatestDatabase()
            }
        }
        
    }
    
    func initialiseDatabase(runQueue: dispatch_queue_t = dispatch_get_main_queue()) {
        
        //Find the file and get the version number from its filename
        
        let expandedDatabaseDirectory = try! NSFileManager.defaultManager().contentsOfDirectoryAtPath(UpdateManager.zipFolderExpandedPath)
        var expandedDatabasePath: String!
        
        for file in expandedDatabaseDirectory {
            
            if file.hasSuffix("sqlite3") {
                
                expandedDatabasePath = UpdateManager.zipFolderExpandedPath + "/" + file
                
                var expandedDatabaseVersion = file.stringByReplacingOccurrencesOfString("database-", withString: "")
                expandedDatabaseVersion = expandedDatabaseVersion.stringByReplacingOccurrencesOfString(".sqlite3", withString: "")
                
                setDatabaseVersion(expandedDatabaseVersion)
                break
                
            }
            
        }
        
        if NSFileManager.defaultManager().fileExistsAtPath(DatabaseManager.databasePath) {
            DatabaseManager.sharedInstance.disconnect()
            try! NSFileManager.defaultManager().removeItemAtPath(DatabaseManager.databasePath)
        }
        
        try! NSFileManager.defaultManager().moveItemAtPath(expandedDatabasePath, toPath: DatabaseManager.databasePath)
        
        //dispatch_sync(dispatch_get_main_queue()) { () -> Void in
            self.removeTemporaryFiles()
        //}
        
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
