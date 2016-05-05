//
//  JourneySegmentIndicator.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 29/12/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

enum JourneySegmentType {
    case StartSegment
    case TransitSegment
    case EndSegment
}

class JourneySegmentIndicator: UIView {

    var segmentType: JourneySegmentType = .StartSegment {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var lineColour: UIColor? {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override func drawRect(rect: CGRect) {
        
        if lineColour == nil {
            lineColour = self.tintColor
        }
        
        let context = UIGraphicsGetCurrentContext()
        let circleRadius = self.frame.width / 2.0
        
        CGContextSetFillColorWithColor(context, lineColour!.CGColor)
        
        var backgroundOffset = CGFloat(0.0)
        var backgroundHeight = self.frame.height
        
        if segmentType != .TransitSegment {
            backgroundHeight = self.frame.height / 2.0
        }
        
        if segmentType == .StartSegment {
            backgroundOffset = self.frame.height / 2.0
        }
        
        let backgroundColourFrame = CGRectMake(0, backgroundOffset, self.frame.width, backgroundHeight)
        
        CGContextFillRect(context, backgroundColourFrame)
        
        if segmentType != .TransitSegment {
            let roundedCornerCircleOffset = (self.frame.height / 2.0) - circleRadius
            CGContextFillEllipseInRect(context, CGRectMake(0, roundedCornerCircleOffset, self.frame.width, self.frame.width))
            
            CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor)
            
            let innerCircleDiameter = self.frame.width * 0.6
            let innerCircleInset = (self.frame.width - innerCircleDiameter) / 2.0
            
            let innerCircleYPosition = (self.frame.height / 2.0) - (innerCircleDiameter / 2.0)
            
            CGContextFillEllipseInRect(context, CGRectMake(innerCircleInset, innerCircleYPosition, innerCircleDiameter, innerCircleDiameter))
        }
        
    }

}