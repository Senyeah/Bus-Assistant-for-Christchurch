//
//  BusStopTableViewCell.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 5/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit
import CoreLocation

class BusStopTableViewCell: UITableViewCell {
    
    @IBOutlet var lineThumbnailView: UIView!
    @IBOutlet var stopName: UILabel!
    @IBOutlet var stopNumber: UILabel!
    
    @IBOutlet var stopDistance: UILabel!
    @IBOutlet var walkTimeLabel: UILabel!
    
    var lineThumbnailLabels: [BusLineLabelView] = []
    var existingConstraints: [NSLayoutConstraint] = []
    
    var bottomConstraint: NSLayoutConstraint?
    
    func setDistance(distance: CLLocationDistance) {
        
        var distanceString: String
        
        if distance < 1000 {
            distanceString = String(format: "%.0f metres", distance)
        } else {
            let kilometres = distance / 1000
            distanceString = String(format: "%.2f km", kilometres)
        }
        
        //Walk time calculation
        
        let walkTime = max(1, Int(ceil(distance / 1.389) / 60))
        walkTimeLabel.text = String(walkTime) + " min" + (walkTime > 1 ? "s" : "")
        
        stopDistance.text = distanceString
        
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
       
        lineThumbnailView.setNeedsLayout()
        lineThumbnailView.layoutIfNeeded()
        
        let availableWidth = lineThumbnailView.bounds.size.width
        let minimumHorizontalPadding = CGFloat(10.0)
        
        var currentX = CGFloat(0.0)
        var currentY = CGFloat(0.0)
        
        var thumbnailHeight = CGFloat(0.0)
        
        for thumbnailView in lineThumbnailLabels {
            
            let dimensions = (width: thumbnailView.intrinsicContentSize().width, height: thumbnailView.intrinsicContentSize().height)
            thumbnailHeight = max(dimensions.height, thumbnailHeight)
            
            if (dimensions.width + minimumHorizontalPadding + currentX) > availableWidth {
                currentY += minimumHorizontalPadding + thumbnailHeight
                currentX = 0
            }
            
            if thumbnailView.xConstraint != nil {
                
                thumbnailView.xConstraint!.constant = currentX
                thumbnailView.yConstraint!.constant = currentY
                
            } else {
                
                let xConstraint = NSLayoutConstraint(item: thumbnailView, attribute: .Leading, relatedBy: .Equal, toItem: lineThumbnailView, attribute: .Leading, multiplier: 1.0, constant: currentX)
                let yConstraint = NSLayoutConstraint(item: thumbnailView, attribute: .Top, relatedBy: .Equal, toItem: lineThumbnailView, attribute: .Top, multiplier: 1.0, constant: currentY)
                
                thumbnailView.xConstraint = xConstraint
                thumbnailView.yConstraint = yConstraint
                
                lineThumbnailView.addConstraints([xConstraint, yConstraint])

            }
            
            thumbnailView.setNeedsUpdateConstraints()
            currentX += minimumHorizontalPadding + dimensions.width
            
        }
        
        if bottomConstraint != nil {
            lineThumbnailView.removeConstraint(bottomConstraint!)
        }
        
        bottomConstraint = NSLayoutConstraint(item: lineThumbnailLabels.last!, attribute: .Bottom, relatedBy: .Equal, toItem: lineThumbnailView, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        bottomConstraint!.priority = 999
        
        lineThumbnailView.addConstraint(bottomConstraint!)

    }
    
    
    func setStopLines(lines: [BusLineType]) {
        
        lineThumbnailView.translatesAutoresizingMaskIntoConstraints = false
        
        if lines.count == 0 {
            return
        }
        
        var viewIdentifier = 0
        
        for lineType in lines {
            
            var lineThumbnail: BusLineLabelView
            
            if viewIdentifier + 1 <= lineThumbnailLabels.count {
                
                lineThumbnail = lineThumbnailLabels[viewIdentifier]
                lineThumbnail.setLineType(lineType)
                
                if lineThumbnail.xConstraint != nil {
                    lineThumbnail.removeConstraints([lineThumbnail.xConstraint!, lineThumbnail.yConstraint!])
                }
                
            } else {
                lineThumbnail = BusLineLabelView(lineType: lineType)
                lineThumbnailLabels.append(lineThumbnail)

                lineThumbnailView.addSubview(lineThumbnail)
            }
            
            viewIdentifier += 1
        }
        
        //If we haven't used all of the available labels, remove the extra ones
        
        if viewIdentifier < lineThumbnailLabels.count {
            for label in lineThumbnailLabels[viewIdentifier..<lineThumbnailLabels.count] {
                label.removeFromSuperview()
            }
        
            lineThumbnailLabels = Array(lineThumbnailLabels[0..<viewIdentifier])
        }
        
        self.layoutSubviews()
        
    }

    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}
