//
//  TripSegmentVisualisationView.swift
//  Metro Assistant
//
//  Created by Jack Greenhill on 5/01/16.
//  Copyright © 2016 Miyazu App + Web Design. All rights reserved.
//

import UIKit

class TripSegmentVisualisationView: UIView {

    private var lineLabels: [BusLineLabelView] = []
    
    private var sequenceArrowImages: [UIImageView] = []
    private var sequenceArrowConstraints: [NSLayoutConstraint] = []
    
    let sequenceArrowPadding = CGFloat(10.0)
    
    var routes: [BusLineType] = [] {
        willSet {
            for labelView in lineLabels {
                labelView.xConstraint = nil
                labelView.yConstraint = nil
                
                labelView.removeFromSuperview()
            }
            
            lineLabels.removeAll()
            
            for image in sequenceArrowImages {
                image.removeFromSuperview()
            }
            
            sequenceArrowConstraints.removeAll()
            sequenceArrowImages.removeAll()
        }
        
        didSet {
            for route in routes {
                let labelView = BusLineLabelView(lineType: route)
                
                lineLabels.append(labelView)
                self.addSubview(labelView)
            }
            
            self.layoutSubviews()
        }
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        var xPosition = CGFloat(0.0)
        
        for labelView in lineLabels {
            
            let xConstraint = NSLayoutConstraint(item: labelView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1.0, constant: xPosition)
            let yConstraint = NSLayoutConstraint(item: labelView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0.0)
            
            if labelView.xConstraint != nil {
                self.removeConstraints([labelView.xConstraint!, labelView.yConstraint!])
            }
            
            labelView.xConstraint = xConstraint
            labelView.yConstraint = yConstraint
            
            self.addConstraints([labelView.xConstraint!, labelView.yConstraint!])
            
            xPosition += labelView.intrinsicContentSize().width
            
            if labelView != lineLabels.last! {
                
                let sequenceArrowImage = UIImageView(image: UIImage(named: "SequenceArrow"))
                
                sequenceArrowImage.frame = CGRectMake(0.0, 0.0, 8.5, 16.0)
                sequenceArrowImage.translatesAutoresizingMaskIntoConstraints = false
                
                sequenceArrowImages.append(sequenceArrowImage)
                
                let sequenceArrowXConstraint = NSLayoutConstraint(item: sequenceArrowImage, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1.0, constant: xPosition + sequenceArrowPadding)
                let sequenceArrowYConstraint = NSLayoutConstraint(item: sequenceArrowImage, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0.0)
                
                sequenceArrowConstraints.appendContentsOf([sequenceArrowXConstraint, sequenceArrowYConstraint])
                
                self.addSubview(sequenceArrowImage)
                self.addConstraints([sequenceArrowXConstraint, sequenceArrowYConstraint])
                
                xPosition += sequenceArrowImage.frame.width + 2 * sequenceArrowPadding
                
            }
            
        }
        
        self.updateConstraintsIfNeeded()
        
    }

}
