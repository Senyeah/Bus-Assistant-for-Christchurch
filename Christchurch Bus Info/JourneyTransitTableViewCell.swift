//
//  JourneyTransitTableViewCell.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 21/12/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

class JourneyTransitTableViewCell: UITableViewCell {

    @IBOutlet var lineLabel: BusLineLabelView!
    @IBOutlet var tripStopIndicator: JourneySegmentIndicator!
    
    @IBOutlet var routeLabel: UILabel!
    @IBOutlet var routeInfoLabel: UILabel!
    
    @IBOutlet var transitTypeImageView: UIImageView!
    @IBOutlet var lineInfoLabelLeadingConstraint: NSLayoutConstraint!
    
    var isBusJourney: Bool = true {
        didSet {
            if isBusJourney {
                transitTypeImageView.image = UIImage(named: "BusTime")
            } else {
                transitTypeImageView.image = UIImage(named: "Person")
            }
        }
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
