//
//  BusStopTableViewCell.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 5/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

class BusStopTableViewCell: UITableViewCell {
    
    @IBOutlet var lineThumbnailView: UIView!
    @IBOutlet var stopName: UILabel!
    @IBOutlet var stopNumber: UILabel!
    
    var lineThumbnailLabels: [BusLineLabelView] = []
    
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
        
        let labelsUsed = viewIdentifier + 1

        //Are there more than we used?
        
        if labelsUsed < lineThumbnailLabels.count {
            for label in lineThumbnailLabels[labelsUsed..<lineThumbnailLabels.count] {
                label.removeFromSuperview()
            }
        
            lineThumbnailLabels = Array(lineThumbnailLabels[0..<labelsUsed])
        }
            
        let layoutConstraints = NSLayoutConstraint.constraintsWithVisualFormat(layoutString, options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewIdentifierDict)
        lineThumbnailView.addConstraints(layoutConstraints)

    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}
