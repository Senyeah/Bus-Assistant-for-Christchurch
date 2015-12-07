//
//  BusLineLabelView.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 6/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

let LINE_LABEL_RADIUS: CGFloat = 5.0

//Todo: redo the whole fucking thing this is so messy

let purple = UIColor.init(red: 0.33, green: 0.27, blue: 0.53, alpha: 1.00)
let orange = UIColor.init(red: 0.93, green: 0.44, blue: 0.15, alpha: 1.00)
let yellow = UIColor.init(red: 1.00, green: 0.76, blue: 0.00, alpha: 1.00)
let blue = UIColor.init(red: 0.30, green: 0.73, blue: 0.94, alpha: 1.00)
let green = UIColor.init(red: 0.49, green: 0.90, blue: 0.27, alpha: 1.00)

enum OrbiterDirection {
    case Clockwise
    case AntiClockwise
}

enum BusLineType {
    case PurpleLine
    case OrangeLine
    case BlueLine
    case YellowLine
    case Orbiter(OrbiterDirection)
    case NumberedRoute(String)
}


class BusLineLabelView: UIView {
    
    var lineType: BusLineType?
    var cellBackgroundColour: UIColor?
    
    var viewConstraints: [NSLayoutConstraint]!
    
    var widthConstraint: NSLayoutConstraint!
    var heightConstraint: NSLayoutConstraint!
    
    var xConstraint: NSLayoutConstraint?
    var yConstraint: NSLayoutConstraint?
    
    let label = UILabel()
    
    override func intrinsicContentSize() -> CGSize {
        return CGSizeMake(widthConstraint.constant, heightConstraint.constant)
    }
    
    func setLineType(lineType: BusLineType) {
        
        self.invalidateIntrinsicContentSize()
        
        switch lineType {
        case .PurpleLine:
            cellBackgroundColour = purple
        case .OrangeLine:
            cellBackgroundColour = orange
        case .BlueLine:
            cellBackgroundColour = blue
        case .YellowLine:
            cellBackgroundColour = yellow
        case .Orbiter(_):
            cellBackgroundColour = green
        case .NumberedRoute(_):
            cellBackgroundColour = UIColor.clearColor()
        }
        
        label.layer.backgroundColor = cellBackgroundColour?.CGColor
        
        //Configure the label
        
        self.lineType = lineType

        switch lineType {
        case .Orbiter(_):
            label.textColor = UIColor.redColor()
        case .NumberedRoute(_):
            label.textColor = self.tintColor
        default:
            label.textColor = UIColor.whiteColor()
        }
        
        var labelText: String
        
        switch lineType {
        case .PurpleLine:
            labelText = "P"
        case .OrangeLine:
            labelText = "O"
        case .BlueLine:
            labelText = "B"
        case .YellowLine:
            labelText = "Y"
        case .Orbiter(let direction):
            labelText = (direction == .Clockwise) ? "Oc" : "Oa"
        case .NumberedRoute(let routeNo):
            labelText = routeNo
        }
        
        
        label.text = labelText
        
        //Stroke if necessary
        
        switch lineType {
        case .NumberedRoute(_):
            self.layer.borderWidth = 1.0
        default:
            self.layer.borderWidth = 0.0
        }
        
        //Compute the dimensions of the view based on the size of the text in the label
        
        let intrinsicSize = label.intrinsicContentSize()
        let padding: CGFloat = 5.0
        
        var width = 2 * padding + intrinsicSize.width
        let height = 2 * padding + intrinsicSize.height
        
        if width < height {
            width = height
        }
        
        if viewConstraints != nil {
            self.removeConstraints(viewConstraints)
        }
        
        viewConstraints = []

        widthConstraint = NSLayoutConstraint(item: self, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: width)
        heightConstraint = NSLayoutConstraint(item: self, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: height)
        
        viewConstraints.appendContentsOf([widthConstraint, heightConstraint])
        
        let labelWidthConstraint = NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[label]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["label": label])
        viewConstraints.appendContentsOf(labelWidthConstraint)
        
        let labelHeightConstraint = NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[label]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["label": label])
        viewConstraints.appendContentsOf(labelHeightConstraint)
        
        self.addConstraints(viewConstraints)
        
    }
    
    
    func initView() {
        
        self.setContentCompressionResistancePriority(1000, forAxis: .Vertical)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.layer.cornerRadius = LINE_LABEL_RADIUS
        self.layer.borderColor = self.tintColor.CGColor
        
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.mainScreen().scale
        
        let preferredFontDescriptor = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody)
        let pointSize = preferredFontDescriptor.pointSize
        
        label.font = UIFont.boldSystemFontOfSize(pointSize)
        label.textAlignment = .Center
        
        label.translatesAutoresizingMaskIntoConstraints = false
        
        label.layer.cornerRadius = LINE_LABEL_RADIUS
        label.backgroundColor = UIColor.clearColor()
        
        self.addSubview(label)
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initView()
    }
    
    
    init(lineType: BusLineType) {
        super.init(frame: CGRectZero)
        
        self.initView()
        self.setLineType(lineType)
    }
}
