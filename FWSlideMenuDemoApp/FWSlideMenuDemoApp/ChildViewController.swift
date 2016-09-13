//
//  FWSlideOverChildViewController.swift
//  FWSlideMenu
//
//  Created by Felix Wehnert on 18.01.16.
//  Copyright © 2016 Felix Wehnert. All rights reserved.
//

import UIKit
import FWSlideMenu
open class ChildViewController: UITableViewController {
    
    @IBAction func open(_ sender: UIBarButtonItem) {
        let controller = self.navigationController?.parent as! FWSlideMenuController
        controller.openSlideMenu()
    }
    override open func viewDidLoad() {
        
    }
}
