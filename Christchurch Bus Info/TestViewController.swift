//
//  TestViewController.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 6/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

class TestViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let test = BusLineLabelView(lineType: .Orbiter(.Clockwise))
        
        var frame = test.frame
        frame.origin.x = 100
        frame.origin.y = 100
        
        test.frame = frame
        
        self.view.addSubview(test)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
