//
//  TableViewLoadingBackgroundView.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 20/12/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

class TableViewLoadingBackgroundView: UIView {

    static func initView() -> TableViewLoadingBackgroundView {
        let instance = NSBundle.mainBundle().loadNibNamed("TableViewLoadingBackgroundView", owner: self, options: nil).first as! TableViewLoadingBackgroundView
        return instance
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}