//
//  RouteStopTableViewCell.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 14/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

class RouteStopTableViewCell: UITableViewCell {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var timeRemainingLabel: UILabel!
    
    @IBOutlet var lineLabel: BusLineLabelView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
