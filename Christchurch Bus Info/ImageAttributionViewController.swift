//
//  ImageAttributionViewController.swift
//  Bus Assistant for Christchurch
//
//  Created by Jack Greenhill on 27/01/16.
//  Copyright © 2016 Miyazu App + Web Design. All rights reserved.
//

import UIKit

class ImageAttributionViewController: UIViewController {

    @IBOutlet var webView: UIWebView!
    
    override func viewDidLoad() {
        
        let pageSourcePath = NSBundle.mainBundle().pathForResource("attribution", ofType: "html")!
        let pageSource = try! String(contentsOfFile: pageSourcePath, encoding: NSUTF8StringEncoding)
        
        webView.loadHTMLString(pageSource, baseURL: nil)
        
    }
    
}
