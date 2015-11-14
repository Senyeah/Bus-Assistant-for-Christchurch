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

    var lineThumbnailLabels: [BusLineLabelView] = []
    var existingConstraints: [NSLayoutConstraint]!

    
    func setDistance(distance: CLLocationDistance) {
        
        var distanceString: String
        
        if distance < 1000 {
            distanceString = String(format: "%.0f metres", distance)
        } else {
            let kilometres = distance / 1000
            distanceString = String(format: "%.2f km", kilometres)
        }
        
        stopDistance.text = distanceString
        
    }
    
    
    func setStopLines(lines: [BusLineType]) {
        
        if lines.count == 0 {
            return
        }
        
        var layoutString: String = "|"
        
        var viewIdentifierDict = [String: BusLineLabelView]()
        var viewIdentifier = 0
        
        for lineType in lines {
            
            var lineThumbnail: BusLineLabelView
            
            if viewIdentifier + 1 <= lineThumbnailLabels.count {
                
                lineThumbnail = lineThumbnailLabels[viewIdentifier]
                
                //Change the style
                lineThumbnail.setLineType(lineType)
                
            } else {
                             
                //We need to allocate another
                
                lineThumbnail = BusLineLabelView(lineType: lineType)
                lineThumbnailLabels.append(lineThumbnail)

                lineThumbnailView.addSubview(lineThumbnail)
                
                let topAlignmentConstraint = NSLayoutConstraint(item: lineThumbnail, attribute: .Top, relatedBy: .Equal, toItem: lineThumbnailView, attribute: .Top, multiplier: 1.0, constant: 0.0)
                lineThumbnailView.addConstraint(topAlignmentConstraint)
                
                let bottomAlignmentConstraint = NSLayoutConstraint(item: lineThumbnail, attribute: .Bottom, relatedBy: .Equal, toItem: lineThumbnailView, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
                lineThumbnailView.addConstraint(bottomAlignmentConstraint)
                
            }
            
            let viewIdentifierString = "v\(viewIdentifier)"
           
            viewIdentifierDict[viewIdentifierString] = lineThumbnail
            layoutString += "[\(viewIdentifierString)]-"
            
            //Flexible space to the trailing edge if we're the last view
            
            if viewIdentifier == lines.count - 1 {
                layoutString += "(>=8)-|"
            }
            
            viewIdentifier++
            
        }
        
        //If we haven't used all of the available labels, remove the extra ones
        
        if viewIdentifier < lineThumbnailLabels.count {
            for label in lineThumbnailLabels[viewIdentifier..<lineThumbnailLabels.count] {
                label.removeFromSuperview()
            }
        
            lineThumbnailLabels = Array(lineThumbnailLabels[0..<viewIdentifier])
        }
        
        let lineThumbnailConstraints = NSLayoutConstraint.constraintsWithVisualFormat(layoutString, options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewIdentifierDict)
        
        //Remove any existing constraints as it may have been reused
        
        if existingConstraints != nil {
            self.removeConstraints(existingConstraints)
        }
        
        existingConstraints = lineThumbnailConstraints
        
        lineThumbnailView.addConstraints(lineThumbnailConstraints)

    }

    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let preferredFontDescriptor = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody)
        let pointSize = preferredFontDescriptor.pointSize
        
        stopName.font = UIFont.systemFontOfSize(pointSize, weight: UIFontWeightMedium)
    }
    
}
