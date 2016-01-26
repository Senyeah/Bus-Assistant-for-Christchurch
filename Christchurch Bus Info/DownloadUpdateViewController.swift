//
//  DownloadUpdateViewController.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 24/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

protocol DownloadUpdateViewControllerDelegate {
    func currentlyDownloadingUpdateShouldCancel()
}

class DownloadUpdateViewController: UIViewController {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var progressLabel: UILabel!
    @IBOutlet var progressBar: UIProgressView!
    
    var delegate: DownloadUpdateViewControllerDelegate?
    
    @IBAction func cancelButtonPressed() {
        delegate?.currentlyDownloadingUpdateShouldCancel()
    }
    
}
