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
    var lineThumbnailLabels: [BusLineLabelView] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        //temporary
        let testLines: [BusLineType] = [.PurpleLine, .YellowLine, .BlueLine, .OrangeLine, .Orbiter(.AntiClockwise), .NumberedRoute("Fuck It")]
        var xPosition: CGFloat = 0.0
        
        for line in testLines {
            let label = BusLineLabelView(lineType: line)
            
            var frame = label.frame
            frame.origin.x = xPosition
            
            xPosition += frame.width + 8
            
            label.frame = frame
            
            lineThumbnailView.addSubview(label)
            lineThumbnailLabels.append(label)
        }
    }
    
    /* This is necessary because the background colour of every UIView in the cell
     * is set to clear on cell highlight. It's absolutely ridiculous that this is
     * the only solution
     */

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
