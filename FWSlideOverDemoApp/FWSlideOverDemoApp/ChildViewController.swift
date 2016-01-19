//
//  FWSlideOverChildViewController.swift
//  FWSlideMenu
//
//  Created by Felix Wehnert on 18.01.16.
//  Copyright © 2016 Felix Wehnert. All rights reserved.
//

import UIKit
import FWSlideMenu
public class ChildViewController: UITableViewController {
    
    @IBAction func open(sender: UIBarButtonItem) {
        let controller = self.navigationController?.parentViewController as! FWSlideMenuController
        controller.openSlideMenu()
    }
    override public func viewDidLoad() {
        
    }
}
