//
//  LineStopIndicator.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 15/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

enum StopType {
    case LineStart
    case IntermediateStop
    case LineEnd
}

class LineStopIndicator: UIView {

    var isMajorStop = true
    var stopType: StopType = .IntermediateStop {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var strokeColour = UIColor.blackColor()
    let lineWidth = CGFloat(3.0)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawRect(rect: CGRect) {
        
        let context = UIGraphicsGetCurrentContext()
        
        let lineStartX = (rect.width / 2) - (lineWidth / 2)
        var lineStartY: CGFloat = 0.0
        
        if stopType == .LineStart {
            lineStartY = rect.height / 2
        }
        
        var lineEndY = rect.height
        
        if stopType == .LineEnd {
            lineEndY /= 2
        }
        
        let lineFrame = CGRectMake(lineStartX, lineStartY, lineWidth, lineEndY)
        
        CGContextSetFillColorWithColor(context, strokeColour.CGColor);
        CGContextFillRect(context, lineFrame);
        
        //Draw the circle
            
        let circleRadius = CGFloat(isMajorStop ? 14.0 : 10.0)
            
        let circleX = (rect.width / 2) - (circleRadius / 2)
        let circleY = (rect.height / 2) - (circleRadius / 2)
            
        CGContextFillEllipseInRect(context, CGRectMake(circleX, circleY, circleRadius, circleRadius))
            
        if isMajorStop == false {
                
            CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor);
                
            let innerCircleRadius = circleRadius * 0.6
            
            let innerCircleX = (rect.width / 2) - (innerCircleRadius / 2)
            let innerCircleY = (rect.height / 2) - (innerCircleRadius / 2)
                
            CGContextFillEllipseInRect(context, CGRectMake(innerCircleX, innerCircleY, innerCircleRadius, innerCircleRadius))
            
        }
        
    }

}
