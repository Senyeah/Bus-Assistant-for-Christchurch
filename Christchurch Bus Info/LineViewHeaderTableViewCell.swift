//
//  LineViewHeaderTableViewCell.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 15/11/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

class LineViewHeaderTableViewCell: UITableViewCell {

    @IBOutlet var lineNameLabel: UILabel!
    @IBOutlet var routeNameLabel: UILabel!
    
    @IBOutlet var lineLabel: BusLineLabelView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        lineLabel.setLineType(.PurpleLine)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
