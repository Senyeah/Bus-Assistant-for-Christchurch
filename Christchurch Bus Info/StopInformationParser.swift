//
//  StopInformationParser.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 14/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

protocol StopInformationParserDelegate {
    func stopInformationParser(parser: StopInformationParser, didReceiveStopInformation info: [[String: AnyObject]])
}

let STOP_ARRIVAL_INFO_URL = "http://rtt.metroinfo.org.nz/rtt/public/utility/file.aspx?ContentType=SQLXML&Name=JPRoutePositionET2&PlatformNo="

class StopInformationParser: NSObject, NSXMLParserDelegate {
    
    var delegate: StopInformationParserDelegate?
    var stopNumber: String!
    
    var stopInfoData: NSData!
    var xmlParser: NSXMLParser!
    
    var stopInformation: [[String: AnyObject]] = []
    var rootNode: String?
    
    var currentItem: [String: AnyObject] = [:]
    
    var destinationName: String?
    var routeNumber: String?
    
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes attributeDict: [String : String]) {
        
        if rootNode == nil {
            rootNode = elementName
        }
        
        if attributeDict["RouteNo"] != nil {
            routeNumber = attributeDict["RouteNo"]!
        }
        
        if routeNumber != nil {
            currentItem["route_no"] = routeNumber
        }
        
        if elementName == "Destination" && attributeDict["Name"] != nil {
            destinationName = attributeDict["Name"]
        }
        
        if destinationName != nil {
            currentItem["name"] = destinationName
        }
        
        if attributeDict["ETA"] != nil {
            currentItem["eta"] = Int(attributeDict["ETA"]!)!
        }
        
        if attributeDict["TripID"] != nil {
            currentItem["trip_id"] = attributeDict["TripID"]!
        }
        
    }
    
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        
        if elementName == "Trip" {
            
            stopInformation.append(currentItem)
            currentItem.removeAll()
            
        } else if elementName == rootNode! {
            
            //Sort by eta ascending
            
            stopInformation.sortInPlace({
                Int($0["eta"] as! NSNumber) < Int($1["eta"] as! NSNumber)
            })
            
            //Tell our delegate that we have new data
            delegate?.stopInformationParser(self, didReceiveStopInformation: stopInformation)
            
        }
        
    }

    
    func updateData() {
        
        stopInformation = []
        
        let updateURL = NSURL(string: STOP_ARRIVAL_INFO_URL + stopNumber)!
        let request = NSURLRequest(URL: updateURL)
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue(), completionHandler: { (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
                   
            guard let receivedData = data else {
                return
            }
        
            var xmlContents = NSString(data: receivedData, encoding: NSUTF8StringEncoding)!
        
            //Uncomment if you're working at 4am when no buses run
            
      //  let bundledArrivalInfo = NSBundle.mainBundle().pathForResource("info", ofType: "xml")!
    //var xmlContents = try! NSString(contentsOfFile: bundledArrivalInfo, encoding: NSUTF8StringEncoding)
        
            //Thank you Metro for giving us invalid XML!
            
            //We need to ensure if at some point they give us valid
            //escaped XML, it's not broken by us 'fixing' it
            
            //Or else '&amp;' would become '&amp;amp;'
            
            xmlContents = xmlContents.stringByReplacingOccurrencesOfString("&amp;", withString: "&")
            xmlContents = xmlContents.stringByReplacingOccurrencesOfString("&", withString: "&amp;")
            
            let data = xmlContents.dataUsingEncoding(NSUTF8StringEncoding)!
            
            self.xmlParser = NSXMLParser(data: data)
            self.xmlParser.delegate = self
            self.xmlParser.parse()
            
        })
        
    }
    
    
    init(stopNumber: String) {
        super.init()
        self.stopNumber = stopNumber
    }
    
    
}
