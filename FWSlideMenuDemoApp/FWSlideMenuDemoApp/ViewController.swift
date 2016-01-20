//
//  ViewController.swift
//  FWSlideOverDemoApp
//
//  Created by Felix Wehnert on 18.01.16.
//  Copyright © 2016 Felix Wehnert. All rights reserved.
//

import UIKit
import FWSlideMenu

class ViewController: FWDefaultSlideMenuViewController {
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    @IBAction func vca(sender: UIButton) {
        print("a")
        controller!.displayViewController(controller!.childViewControllers[0])
    }
    
    @IBAction func vcb(sender: UIButton) {
        print("b")
        controller!.displayViewController(controller!.childViewControllers[1])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = UIImage(named: "woman")
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func progressChanged(progress: CGFloat) {
        self.imageView.alpha = 1-progress
        self.topConstraint.constant = -50*progress + 8
        self.view.layoutIfNeeded()
    }
    
    override func progressFinished(state: SlideState) {
        UIView.animateWithDuration(0.3) { () -> Void in
            if state == .Opened {
                self.imageView.alpha = 1
                self.topConstraint.constant = 8
                self.view.layoutIfNeeded()
            } else {
                self.imageView.alpha = 0
                self.topConstraint.constant = -242
                self.view.layoutIfNeeded()
            }
        }
    }
}

