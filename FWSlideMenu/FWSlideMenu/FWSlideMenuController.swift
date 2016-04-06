//
//  FWSlideOverController.swift
//  FWSlideMenu
//
//  Created by Felix Wehnert on 18.01.16.
//  Copyright © 2016 Felix Wehnert. All rights reserved.
//

import UIKit

public enum SlideState {
    case Opened
    case Opening
    case Closed
    case Closing
}

public protocol FWSlideMenuViewController {
    func progressChanged(progress: CGFloat)
    func progressFinished(state: SlideState)
    func setController(controller: FWSlideMenuController)
}
/*
 
 
 Important things you need to know:
    - Your childView is not responding to any user interactions until slideState set to .Closed and we'll use the userInteractionEnabled property of YOUR view for this.
    - We add a new layer to your childs you submitted to us.
 
 Workflow of FWSlideMenu:
 
 1. FWSlideMenuController is initiated with the slider and the "child views"
 2. Childs added to childViews
!   1. A new transparentLayer will be added to your view
 
 3. viewDidLoad:    
    1. Touch guesture recognizers are initiiated
!   2. Your slideOverView is stretched to exactly slideOverFactor times of the FWSlideMenuControllers width and will be positioned outside of the view
    3. First VC of array will be shown
 
 On slide or openSlideMenu: at every tick
    1. moveSlideMenu will determine if view is closing, opening, closed or opened and will move your slideMenu to the right position
        Progress will be transmitted (-> Protocol) to you right before our animation.
    2. animateActiveChild: will do 3D animations on the currently active child view.
 
 Your slideMenu should fire our displayViewController method to show new or known view controllers.
 
 
 */
public class FWSlideMenuController: UIViewController, UIGestureRecognizerDelegate {
    
    private var slideState: SlideState  = .Closed {
        didSet {
            if slideState != .Closed {
                self.panRecognizer?.enabled = true
                self.activeChild!.view.userInteractionEnabled = false
            } else {
                self.panRecognizer?.enabled = false
                self.activeChild!.view.userInteractionEnabled = true
            }
        }
    }
    
    
    var slideMenuViewController: UIViewController
    
    private var screenEdgePanRecognizer: UIScreenEdgePanGestureRecognizer?
    private var panRecognizer: UIPanGestureRecognizer?
    private var tapRecognizer: UITapGestureRecognizer?
    
    private var activeChild: UIViewController?
    private let transparentLayerKey = "FWSlideMenuTransparentLayerKey"
    private let transparentLayerAnimationKey = "FWSlideMenuTransparentLayerAnimationKey"
    
    public var slideOverFactor: CGFloat = 0.7
    public var slideDuration: Double = 0.4
    private let zoomFactor: CGFloat = 0.9
    
    public init<T:UIViewController where T:FWSlideMenuViewController>(childs: [UIViewController], slideMenuController: T) {
        self.slideMenuViewController = slideMenuController
        super.init(nibName: nil, bundle: nil)
        (self.slideMenuViewController as! FWSlideMenuViewController).setController(self)
        
        for vc in childs {
            self.addChildViewController(vc)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.slideMenuViewController = FWDefaultSlideMenuViewController()
        super.init(coder: aDecoder)
    }
    
    override public func addChildViewController(childController: UIViewController) {
        childController.view.layer.allowsEdgeAntialiasing = true

        let transparentLayer = CALayer()
        transparentLayer.backgroundColor = UIColor.blackColor().CGColor
        transparentLayer.frame = childController.view.frame
        transparentLayer.opacity = 0
        transparentLayer.name = self.transparentLayerKey
        childController.view.layer.addSublayer(transparentLayer)
        
        super.addChildViewController(childController)
        childController.view.frame = self.view.frame
    }
    
    public func openSlideMenu() {
        
        UIView.animateWithDuration(self.slideDuration, animations: { () -> Void in
            self.slideMenuViewController.view.frame.origin = CGPoint(x: 0, y: 0)
            self.activeChild?.view.layer.transform = CATransform3DMakeScale(self.zoomFactor,self.zoomFactor,self.zoomFactor)
        })
        
        // Get our transparentLayer.
        let transparentLayer = self.activeChild?.view.layer.sublayers!.filter({$0.name == self.transparentLayerKey})[0]
        
        // Create the opacity animation function
        let basicAnimation = CABasicAnimation(keyPath: "opacity")
        basicAnimation.duration = 0.35
        basicAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        basicAnimation.fromValue = transparentLayer!.opacity
        
        // animate to 0 if closed; animate to 0.5 if opening
        basicAnimation.toValue = 0.5
        transparentLayer!.opacity = 0.5
        
        // exec the animation function
        transparentLayer!.addAnimation(basicAnimation, forKey: self.transparentLayerAnimationKey)
        
        self.slideState = .Opened
        (self.slideMenuViewController as! FWSlideMenuViewController).progressFinished(.Opened)
    }
    
    public func closeSlideMenu() {
    
        UIView.animateWithDuration(self.slideDuration, animations: { () -> Void in
            self.slideMenuViewController.view.frame.origin = CGPoint(x: -self.slideMenuViewController.view.frame.width, y: 0)
            self.activeChild?.view.layer.transform = CATransform3DIdentity
        })
        
        // Get our transparentLayer.
        let transparentLayer = self.activeChild?.view.layer.sublayers!.filter({$0.name == self.transparentLayerKey})[0]
        
        // Create the opacity animation function
        let basicAnimation = CABasicAnimation(keyPath: "opacity")
        basicAnimation.duration = 0.35
        basicAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        basicAnimation.fromValue = 0.5
        
        // animate to 0 if closed; animate to 0.5 if opening
        basicAnimation.toValue = 0
        transparentLayer!.opacity = 0
        
        // exec the animation function
        transparentLayer!.addAnimation(basicAnimation, forKey: self.transparentLayerAnimationKey)
 
        self.slideState = .Closed
        (self.slideMenuViewController as! FWSlideMenuViewController).progressFinished(.Closed)
    }
    
    public func displayViewController(vc: UIViewController) {
        if !self.childViewControllers.contains(vc) {
            self.addChildViewController(vc)
        }
        
        if self.activeChild == vc {
            // do nothing
        } else if self.activeChild == nil {
            self.view.addSubview(vc.view)
            self.view.bringSubviewToFront(self.slideMenuViewController.view)
        } else {
            self.flip(vc)
        }
        
        self.activeChild = vc
        self.closeSlideMenu()
    }
    
    public func displayViewController(index index: Int) {
        self.displayViewController(self.childViewControllers[index])
    }
    
    override public func viewDidLoad() {
        
        self.screenEdgePanRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(recognizedSwipeGesture))
        self.screenEdgePanRecognizer?.edges = UIRectEdge.Left
        self.view.addGestureRecognizer(self.screenEdgePanRecognizer!)
        
        self.panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(recognizedSwipeGesture))
        self.panRecognizer?.maximumNumberOfTouches = 1
        self.panRecognizer?.enabled = false
        self.view.addGestureRecognizer(self.panRecognizer!)
        
        self.tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(recognizedTapGesture))
        self.tapRecognizer?.numberOfTapsRequired = 1
        self.tapRecognizer?.numberOfTouchesRequired = 1
        self.tapRecognizer?.cancelsTouchesInView = false // otherwise slideMenu is untappable
        self.view.addGestureRecognizer(self.tapRecognizer!)
        
        self.slideMenuViewController.view.frame = CGRect(x: self.view.frame.width*(-self.slideOverFactor), y: 0, width: self.view.frame.width*self.slideOverFactor, height: self.view.frame.height)
        self.view.addSubview(self.slideMenuViewController.view)
        self.slideMenuViewController.view.layer.zPosition = 1000
        self.slideMenuViewController.didMoveToParentViewController(self)
        
        
        if childViewControllers.count != 0 {
            self.displayViewController(childViewControllers[0])
        } else {
            fatalError("You did not provide a ViewController at init")
        }
        
    }
    
    private func flip(to: UIViewController) {
        let old = self.activeChild!
        self.activeChild = to

        UIView.animateWithDuration(0, animations: { () -> Void in
            self.activeChild?.view.layer.transform = CATransform3DMakeScale(self.zoomFactor,self.zoomFactor,self.zoomFactor)
        })
        
        // Get our transparentLayer.
        let transparentLayer = self.activeChild?.view.layer.sublayers!.filter({$0.name == self.transparentLayerKey})[0]
        transparentLayer!.opacity = 0.5
        

        
        self.view.addSubview(to.view)
        old.view.removeFromSuperview()
        self.view.bringSubviewToFront(self.slideMenuViewController.view)
        self.closeSlideMenu()
    }
    
    func recognizedTapGesture(recognizer:UITapGestureRecognizer) {
        if self.slideState == .Opened && recognizer.locationInView(self.view).x >= self.view.frame.size.width*self.slideOverFactor {
            self.closeSlideMenu()
        }
    }
    
    func recognizedSwipeGesture(recognizer:UIGestureRecognizer) {
        
        // If you move your finger from left to the very right you should see the fully ended animation. So lets stop the animation if your finger reached the slideMenuView's width

        
        // Stop do anything when you're moving your finger at the slideMenu. But start dragging if your finger is reaching the edge of slideMenuView
        if slideState == .Opened && recognizer == self.panRecognizer && recognizer.locationInView(self.view).x < (self.slideMenuViewController.view.frame.size.width-20) {
            return
        }
        
        switch recognizer.state {
        case .Changed, .Began, .Possible: // The animation is going on or just started
            let touchPoint = recognizer.locationInView(self.view).x
            self.moveSlideMenu(touchPoint-self.slideMenuViewController.view.frame.width)
            
        case .Ended, .Cancelled, .Failed: // Put the animation to a defined state
            switch self.slideState {
            case .Closing: // If the last known state was closing then close the menu
                self.closeSlideMenu()
            case .Opening: // If the last known state was opening then open the menu
                self.openSlideMenu()
            default:
                break
            }
        }
        
    }
    
    private func moveSlideMenu(x: CGFloat) {
        
        func mapValue(x: CGFloat, in_min: CGFloat, in_max: CGFloat, out_min: CGFloat, out_max: CGFloat) -> CGFloat
        {
            return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
        }

        var point = CGPoint(x: 0, y: 0)
        point.x = min(0, x)
        point.x = max(-self.slideMenuViewController.view.frame.width, point.x)
        
        // Get the current progress between 1 and zoomFactor(=0.9 default)
        let currentProgress: CGFloat = max(mapValue(point.x, in_min: -self.slideMenuViewController.view.frame.width, in_max: 0, out_min: 1, out_max: zoomFactor), zoomFactor)
        
        // Are you about to close or open
        if self.slideMenuViewController.view.frame.origin.x < point.x {
            self.slideState = .Opening
        } else {
            self.slideState = .Closing
        }
        
        // Or did you even close/open?
        if point.x == 0 {
            print("\(NSDate()) open!")
            self.slideState = .Opened
            (self.slideMenuViewController as! FWSlideMenuViewController).progressFinished(.Opened)
        } else if point.x == -self.slideMenuViewController.view.frame.width {
            self.slideState = .Closed
            (self.slideMenuViewController as! FWSlideMenuViewController).progressFinished(.Closed)
        } else { // We're in animation
            print(point.x)
            (self.slideMenuViewController as! FWSlideMenuViewController).progressChanged((currentProgress - 0.9) / 0.1) // convert our currentProgress to interval [0,1]
        }
        
        // Animate the slideMenuView
        self.slideMenuViewController.view.frame.origin = point
      
        
        // Animate all the rest
        self.animateActiveChild(currentProgress)
    }
    
    private func animateActiveChild(progress: CGFloat) {
        
        // Get our transparentLayer.
        let transparentLayer = self.activeChild?.view.layer.sublayers!.filter({$0.name == self.transparentLayerKey})[0]
        
        // Create the opacity animation function
        let basicAnimation = CABasicAnimation(keyPath: "opacity")
        basicAnimation.duration = 0.35
        basicAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        basicAnimation.fromValue = transparentLayer!.opacity
        
        // animate to 0 if closed; animate to 0.5 if opening
        basicAnimation.duration = 0
        basicAnimation.toValue = Float(0.5-(progress-0.9)*(0.5)/(0.1))
        transparentLayer!.opacity = Float(0.5-(progress-0.9)*(0.5)/(0.1))
        
        
        // exec the animation function
        transparentLayer!.addAnimation(basicAnimation, forKey: self.transparentLayerAnimationKey)
        
        // Animate all the 3D stuff of the currently active VC
        if self.slideState == .Opened {
            UIView.animateWithDuration(0.1, animations: { 
                self.activeChild?.view.layer.transform = CATransform3DScale(CATransform3DIdentity, self.zoomFactor, self.zoomFactor, self.zoomFactor)
            })
        } else {
            var transform: CATransform3D = CATransform3DIdentity;
            transform.m34 = 1.0 / 400.0; // This is something like the CSS command "perspective:"
            transform = CATransform3DRotate(transform, 1-progress, 0, 1, 0)
            transform = CATransform3DScale(transform, progress, progress, progress)
            self.activeChild?.view.layer.transform = transform;
        }
    }
    
    
    
    
}
