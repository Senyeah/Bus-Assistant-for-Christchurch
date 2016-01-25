//
//  BusLineLabelView.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 6/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

let LINE_LABEL_RADIUS: CGFloat = 5.0

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
    
    var toString: String {
        switch self {
        case .PurpleLine:
            return "P"
        case .OrangeLine:
            return "O"
        case .BlueLine:
            return "B"
        case .YellowLine:
            return "Y"
        case .Orbiter(let direction):
            return (direction == .Clockwise) ? "Oc" : "Oa"
        case .NumberedRoute(let routeNo):
            return routeNo
        }
    }
    
    func colours() -> (text: UIColor?, background: UIColor?) {
        let colours = DatabaseManager.sharedInstance.lineColourForRoute(self)
        return (text: colours.text, background: colours.background)
    }
    
    init(lineAbbreviationString: String) {
        let linesMap: [String: BusLineType] = ["P": .PurpleLine, "O": .OrangeLine, "Y": .YellowLine, "B": .BlueLine, "Oa": .Orbiter(.AntiClockwise), "Oc": .Orbiter(.Clockwise)]

        if linesMap[lineAbbreviationString] == nil {
            self = .NumberedRoute(lineAbbreviationString)
        } else {
            self = linesMap[lineAbbreviationString]!
        }
    }
}



class BusLineLabelView: UIView {
    
    var cellBackgroundColour: UIColor?
    
    var viewConstraints: [NSLayoutConstraint]!
    
    var widthConstraint: NSLayoutConstraint?
    var heightConstraint: NSLayoutConstraint?
    
    var xConstraint: NSLayoutConstraint?
    var yConstraint: NSLayoutConstraint?
    
    let label = UILabel()
    var lineType: BusLineType?
    
    func setLineType(lineType: BusLineType) {
        
        self.lineType = lineType
        self.invalidateIntrinsicContentSize()
        
        label.layer.backgroundColor = (lineType.colours().background ?? UIColor.clearColor()).CGColor
        label.textColor = lineType.colours().text ?? self.tintColor
        
        label.text = lineType.toString
        
        //Stroke if necessary
        
        if label.textColor == self.tintColor {
            self.layer.borderWidth = 1.0
        } else {
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
        
        viewConstraints.appendContentsOf([widthConstraint!, heightConstraint!])
        
        let labelWidthConstraint = NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[label]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["label": label])
        viewConstraints.appendContentsOf(labelWidthConstraint)
        
        let labelHeightConstraint = NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[label]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["label": label])
        viewConstraints.appendContentsOf(labelHeightConstraint)
        
        self.addConstraints(viewConstraints)
        
    }
    
    override func intrinsicContentSize() -> CGSize {
        if widthConstraint == nil || heightConstraint == nil {
            return CGSizeMake(40.0, 30.0)
        } else {
            return CGSizeMake(widthConstraint!.constant, heightConstraint!.constant)
        }
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
