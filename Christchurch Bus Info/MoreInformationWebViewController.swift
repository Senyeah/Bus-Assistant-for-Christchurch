//
//  MoreInformationWebViewController.swift
//  Bus Assistant for Christchurch
//
//  Created by Jack Greenhill on 27/01/16.
//  Copyright © 2016 Miyazu App + Web Design. All rights reserved.
//

import UIKit

class MoreInformationWebViewController: UIViewController {

    @IBOutlet var webView: UIWebView!
    
    var filePath: String?
    var pageTitle: String = "Information"
    
    override func viewDidLoad() {
        
        self.navigationItem.title = pageTitle
        
        if let pageSourcePath = filePath {
            let pageSource = try! String(contentsOfFile: pageSourcePath, encoding: NSUTF8StringEncoding)
            webView.loadHTMLString(pageSource, baseURL: nil)
        }
        
        //let pageSourcePath = NSBundle.mainBundle().pathForResource("attribution", ofType: "html")!
        
    }
    
}