//
//  JourneyStopTableViewCell.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 21/12/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

class JourneyStopTableViewCell: UITableViewCell {

    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var stopNameLabel: UILabel!
    
    @IBOutlet var stopIndicator: JourneySegmentIndicator!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
