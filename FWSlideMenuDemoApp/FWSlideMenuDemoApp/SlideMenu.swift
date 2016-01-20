//
//  ViewController.swift
//  FWSlideOverDemoApp
//
//  Created by Felix Wehnert on 18.01.16.
//  Copyright © 2016 Felix Wehnert. All rights reserved.
//

import UIKit
import FWSlideMenu

class SlideMenu: FWDefaultSlideMenuViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var topConst: NSLayoutConstraint!
    
    let menu = ["Vertretungsplan", "Klausuren", "Einstellungen", "Termine", "Lehrerliste", "Abmelden"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "pattern")!)
        
        self.imageView.image = UIImage(named: "woman")!
        self.label.text = "Felix Wehnert"
        self.tableView.backgroundColor = UIColor.clearColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menu.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell?
        
        cell = tableView.dequeueReusableCellWithIdentifier("identifier")
        if menu[indexPath.row] == "Abmelden" {
            cell?.backgroundColor = UIColor(red: 255/255, green: 82/255, blue: 82/255, alpha: 0.4)
        }
        cell?.textLabel?.text = menu[indexPath.row]
        return cell!
    }

    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
        self.controller?.displayViewController((self.controller?.childViewControllers[indexPath.row])!)
    }
    
    override func progressChanged(progress: CGFloat) {
        self.imageView.alpha = 1-progress
        self.topConst.constant = -50*progress + 4
        self.view.layoutIfNeeded()

    }
    
    override func progressFinished(state: SlideState) {
        UIView.animateWithDuration(0.3) { () -> Void in
            if state == .Opened {
                self.imageView.alpha = 1
                self.topConst.constant = 4
                self.view.layoutIfNeeded()
            } else {
                self.imageView.alpha = 0
                self.topConst.constant = -46
                self.view.layoutIfNeeded()
            }
        }

    }
}

