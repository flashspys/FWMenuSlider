//
//  ViewController.swift
//  FWSlideOverDemoApp
//
//  Created by Felix Wehnert on 18.01.16.
//  Copyright © 2016 Felix Wehnert. All rights reserved.
//

import UIKit
import FWSlideMenu

class SlideMenu: UIViewController, FWSlideMenuViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var topConst: NSLayoutConstraint!
    
    var backgroundView: UIView?
    
    let menu = ["Vertretungsplan", "Klausuren", "Einstellungen", "Termine", "Lehrerliste", "Abmelden"]

    var slideController: FWSlideMenuController?
    
    func setController(controller: FWSlideMenuController) {
        self.slideController = controller
    }
    
    override func viewDidLoad() {
        
        self.backgroundView = UIView(frame: self.view.frame)
        self.backgroundView?.frame.size.width += 50
        self.backgroundView?.frame.origin.x -= 50
        self.backgroundView?.backgroundColor = UIColor(patternImage: UIImage(named: "pattern")!)
        //self.backgroundView?.layer.zPosition = -1
        self.view.addSubview(self.backgroundView!)
        self.view.sendSubviewToBack(self.backgroundView!)
        self.view.clipsToBounds = true
        
        self.imageView.image = UIImage(named: "woman")!
        self.label.text = "Felix Wehnert"
        self.tableView.backgroundColor = UIColor.clearColor()
        
        super.viewDidLoad()
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
        cell?.selectionStyle = .Blue
        return cell!
    }

    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
        self.slideController?.displayViewController(index: indexPath.row)
    }
    
    func progressChanged(progress: CGFloat) {
        self.imageView.alpha = 1-progress
        self.label.alpha = 1-progress
        self.tableView.alpha = 1-progress
        self.topConst.constant = -50*progress + 15
        self.backgroundView?.frame.origin.x = 50*progress
        self.view.layoutIfNeeded()

    }
    
    func progressFinished(state: SlideState) {
        UIView.animateWithDuration(0.3) { () -> Void in
            if state == .Opened {
                self.imageView.alpha = 1
                self.label.alpha = 1
                self.tableView.alpha = 1
                self.topConst.constant = 15
                self.backgroundView?.frame.origin.x = 0
                self.view.layoutIfNeeded()
            } else {
                self.imageView.alpha = 0
                self.tableView.alpha = 0
                self.label.alpha = 0
                self.topConst.constant = -35
                self.backgroundView?.frame.origin.x = 50
                self.view.layoutIfNeeded()
            }
        }

    }
}

