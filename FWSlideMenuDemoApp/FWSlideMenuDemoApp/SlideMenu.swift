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
    
    func setController(_ controller: FWSlideMenuController) {
        self.slideController = controller
    }
    
    override func viewDidLoad() {
        
        self.backgroundView = UIView(frame: self.view.frame)
        self.backgroundView?.frame.size.width += 50
        self.backgroundView?.frame.origin.x -= 50
        self.backgroundView?.backgroundColor = UIColor(patternImage: UIImage(named: "pattern")!)
        //self.backgroundView?.layer.zPosition = -1
        self.view.addSubview(self.backgroundView!)
        self.view.sendSubview(toBack: self.backgroundView!)
        self.view.clipsToBounds = true
        
        self.imageView.image = UIImage(named: "woman")!
        self.label.text = "Felix Wehnert"
        self.tableView.backgroundColor = UIColor.clear
        
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menu.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell?
        
        cell = tableView.dequeueReusableCell(withIdentifier: "identifier")
        if menu[(indexPath as NSIndexPath).row] == "Abmelden" {
            cell?.backgroundColor = UIColor(red: 255/255, green: 82/255, blue: 82/255, alpha: 0.4)
        }
        cell?.textLabel?.text = menu[(indexPath as NSIndexPath).row]
        cell?.selectionStyle = .blue
        return cell!
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: false)
        self.slideController?.displayViewController(index: (indexPath as NSIndexPath).row)
    }
    
    func progressChanged(_ progress: CGFloat) {
        self.imageView.alpha = 1-progress
        self.label.alpha = 1-progress
        self.tableView.alpha = 1-progress
        self.topConst.constant = -50*progress + 15
        self.backgroundView?.frame.origin.x = 50*progress
        self.view.layoutIfNeeded()

    }
    
    func progressFinished(_ state: SlideState) {
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            if state == .opened {
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
        }) 

    }
}

