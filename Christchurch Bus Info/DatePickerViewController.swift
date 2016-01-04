//
//  DatePickerViewController.swift
//  Christchurch Bus Info
//
//  Created by Jack Greenhill on 20/12/15.
//  Copyright © 2015 Miyazu App + Web Design. All rights reserved.
//

import UIKit

extension NSDate {
    func toShortDateTimeString(alwaysShowDay: Bool = false) -> String {
        let formatter = NSDateFormatter()
        
        formatter.dateStyle = NSCalendar.currentCalendar().isDateInToday(self) && !alwaysShowDay ? .NoStyle : .MediumStyle
        formatter.timeStyle = .ShortStyle
        
        return formatter.stringFromDate(self)
    }
}

protocol DatePickerDelegate {
    func datePickerDidSelectNewDate(date: NSDate)
}

class DatePickerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var datePicker: UIDatePicker!
    
    var delegate: DatePickerDelegate?
    var selectedDate: NSDate?
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("DateCell", forIndexPath: indexPath)
        cell.textLabel?.text = selectedDate!.toShortDateTimeString(true)
        
        return cell
        
    }
    
    @IBAction func doneButtonPressed(sender: AnyObject?) {
        delegate?.datePickerDidSelectNewDate(selectedDate!)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func datePickerValueChanged(sender: AnyObject?) {
        selectedDate = datePicker.date
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectedDate = selectedDate ?? NSDate()
        datePicker.setDate(selectedDate!, animated: false)
    }

}
