//
//  BusLineLabelView.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 6/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

let LINE_LABEL_MIN_WIDTH: CGFloat = 30.0
let LINE_LABEL_HEIGHT: CGFloat = 30.0

let LINE_LABEL_RADIUS: CGFloat = 5.0

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
    
    let label = UILabel()
    
    /*override func drawRect(rect: CGRect) {
        self.layer.backgroundColor = cellBackgroundColour?.CGColor
    }*/
    
    init(lineType: BusLineType) {
        
        super.init(frame: CGRectZero)
        
        //Configure the colour of the label
        
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
        
        self.backgroundColor = cellBackgroundColour
        
        //Configure the label
        
        self.lineType = lineType
        self.layer.cornerRadius = LINE_LABEL_RADIUS
        self.layer.masksToBounds = true
        
        label.backgroundColor = UIColor.clearColor()
        
        switch lineType {
        case .Orbiter(_):
            label.textColor = UIColor.redColor()
        case .NumberedRoute(_):
            label.textColor = self.tintColor
        default:
            label.textColor = UIColor.whiteColor()
        }
        
        label.font = UIFont.systemFontOfSize(17.0, weight: UIFontWeightMedium)
        label.textAlignment = .Center
        
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
            self.layer.borderColor = self.tintColor.CGColor
            self.layer.borderWidth = 1.0
        default:
            break
        }
        
        //Compute the dimensions of the view based on the size of the text in the label
        
        let intrinsicSize = label.intrinsicContentSize()
        let padding = ((LINE_LABEL_HEIGHT - intrinsicSize.height) / 2)
        
        let width = max(LINE_LABEL_MIN_WIDTH, 2 * padding + intrinsicSize.width)
        
        let viewDimensions = CGRectMake(frame.origin.x, frame.origin.y, width, LINE_LABEL_HEIGHT)
        let labelDimensions = CGRectMake(0, 0, width, LINE_LABEL_HEIGHT)
        
        label.frame = labelDimensions
        self.addSubview(label)
        
        self.frame = viewDimensions
        
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
