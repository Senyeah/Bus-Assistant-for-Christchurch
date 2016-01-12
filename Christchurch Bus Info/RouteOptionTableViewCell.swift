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
    
    @IBOutlet var transitTimeLabel: UILabel!
    @IBOutlet var walkTimeLabel: UILabel!
    
    @IBOutlet var tripSegmentsView: TripSegmentVisualisationView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
