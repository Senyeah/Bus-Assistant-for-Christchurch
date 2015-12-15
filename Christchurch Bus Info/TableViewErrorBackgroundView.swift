//
//  TableViewErrorBackgroundView.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 15/12/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

class TableViewErrorBackgroundView: UIView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    @IBOutlet var title: UILabel!
    @IBOutlet var message: UILabel!
    
    static func initView(errorTitle: String, errorDetail: String) -> TableViewErrorBackgroundView {
        let instance = NSBundle.mainBundle().loadNibNamed("TableViewErrorBackgroundView", owner: self, options: nil).first as! TableViewErrorBackgroundView
        
        instance.title.text = errorTitle
        instance.message.text = errorDetail
        
        return instance
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
