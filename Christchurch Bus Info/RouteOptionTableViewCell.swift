//
//  RouteOptionTableViewCell.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 12/12/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

class RouteOptionTableViewCell: UITableViewCell {

    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var durationLabel: UILabel!
    @IBOutlet var routeView: UIView!
    
    @IBOutlet var transitTimeLabel: UILabel!
    @IBOutlet var walkTimeLabel: UILabel!
    
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
                routeView.addSubview(labelView)
            }
            
            self.layoutSubviews()
        }
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        var xPosition = CGFloat(0.0)
            
        for labelView in lineLabels {
            
            let xConstraint = NSLayoutConstraint(item: labelView, attribute: .Leading, relatedBy: .Equal, toItem: routeView, attribute: .Leading, multiplier: 1.0, constant: xPosition)
            let yConstraint = NSLayoutConstraint(item: labelView, attribute: .CenterY, relatedBy: .Equal, toItem: routeView, attribute: .CenterY, multiplier: 1.0, constant: 0.0)
            
            if labelView.xConstraint != nil {
                routeView.removeConstraints([labelView.xConstraint!, labelView.yConstraint!])
            }
            
            labelView.xConstraint = xConstraint
            labelView.yConstraint = yConstraint
            
            routeView.addConstraints([labelView.xConstraint!, labelView.yConstraint!])
            
            xPosition += labelView.intrinsicContentSize().width
            
            if labelView != lineLabels.last! {
                
                let sequenceArrowImage = UIImageView(image: UIImage(named: "SequenceArrow"))
                
                sequenceArrowImage.frame = CGRectMake(0.0, 0.0, 8.5, 16.0)
                sequenceArrowImage.translatesAutoresizingMaskIntoConstraints = false
                
                sequenceArrowImages.append(sequenceArrowImage)
                
                let sequenceArrowXConstraint = NSLayoutConstraint(item: sequenceArrowImage, attribute: .Leading, relatedBy: .Equal, toItem: routeView, attribute: .Leading, multiplier: 1.0, constant: xPosition + sequenceArrowPadding)
                let sequenceArrowYConstraint = NSLayoutConstraint(item: sequenceArrowImage, attribute: .CenterY, relatedBy: .Equal, toItem: routeView, attribute: .CenterY, multiplier: 1.0, constant: 0.0)
                
                sequenceArrowConstraints.appendContentsOf([sequenceArrowXConstraint, sequenceArrowYConstraint])
                
                routeView.addSubview(sequenceArrowImage)
                routeView.addConstraints([sequenceArrowXConstraint, sequenceArrowYConstraint])
                
                xPosition += sequenceArrowImage.frame.width + 2 * sequenceArrowPadding
                
            }
            
        }
        
        routeView.updateConstraintsIfNeeded()
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
