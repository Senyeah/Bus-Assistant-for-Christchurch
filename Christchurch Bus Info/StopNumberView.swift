//
//  StopNumberView.swift
//  Metro Assistant
//
//  Created by Jack Greenhill on 5/01/16.
//  Copyright © 2016 Miyazu App + Web Design. All rights reserved.
//

import UIKit

@IBDesignable
class StopNumberView: UIView {
    
    var stopNumber: String = "12356"
    var stopLabel: UILabel?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initView()
    }
    
    func initView() {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.layer.cornerRadius = LINE_LABEL_RADIUS
        
        self.layer.borderColor = UIColor.blackColor().CGColor
        self.layer.borderWidth = 1.0
        
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.mainScreen().scale
        
        stopLabel = UILabel(frame: CGRectMake(0, 0, self.frame.width, self.frame.height))
        
        stopLabel!.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        stopLabel!.text = stopNumber
        
        self.addSubview(stopLabel!)
    }
    

}
