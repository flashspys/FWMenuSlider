//
//  FWSlideOverController.swift
//  FWSlideMenu
//
//  Created by Felix Wehnert on 18.01.16.
//  Copyright © 2016 Felix Wehnert. All rights reserved.
//

import UIKit

public enum SlideState {
    case opened
    case opening
    case closed
    case closing
}

public protocol FWSlideMenuViewController {
    func progressChanged(_ progress: CGFloat)
    func progressFinished(_ state: SlideState)
    func setController(_ controller: FWSlideMenuController)
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
open class FWSlideMenuController: UIViewController, UIGestureRecognizerDelegate {
    
    fileprivate var slideState: SlideState  = .closed {
        didSet {
            if slideState != .closed {
                self.panRecognizer?.isEnabled = true
                self.activeChild!.view.isUserInteractionEnabled = false
            } else {
                self.panRecognizer?.isEnabled = false
                self.activeChild!.view.isUserInteractionEnabled = true
            }
        }
    }
    
    
    var slideMenuViewController: UIViewController
    
    fileprivate var screenEdgePanRecognizer: UIScreenEdgePanGestureRecognizer?
    fileprivate var panRecognizer: UIPanGestureRecognizer?
    fileprivate var tapRecognizer: UITapGestureRecognizer?
    
    fileprivate var activeChild: UIViewController?
    fileprivate let transparentLayerKey = "FWSlideMenuTransparentLayerKey"
    fileprivate let transparentLayerAnimationKey = "FWSlideMenuTransparentLayerAnimationKey"
    
    open var slideOverFactor: CGFloat = 0.7
    open var slideDuration: Double = 0.4
    fileprivate let zoomFactor: CGFloat = 0.9
    
    public init<T:UIViewController>(childs: [UIViewController], slideMenuController: T) where T:FWSlideMenuViewController {
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
    
    override open func addChildViewController(_ childController: UIViewController) {
        childController.view.layer.allowsEdgeAntialiasing = true

        let transparentLayer = CALayer()
        transparentLayer.backgroundColor = UIColor.black.cgColor
        transparentLayer.frame = childController.view.frame
        transparentLayer.opacity = 0
        transparentLayer.name = self.transparentLayerKey
        childController.view.layer.addSublayer(transparentLayer)
        
        super.addChildViewController(childController)
        childController.view.frame = self.view.frame
    }
    
    open func openSlideMenu() {
        
        UIView.animate(withDuration: self.slideDuration, animations: { () -> Void in
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
        transparentLayer!.add(basicAnimation, forKey: self.transparentLayerAnimationKey)
        
        self.slideState = .opened
        (self.slideMenuViewController as! FWSlideMenuViewController).progressFinished(.opened)
    }
    
    open func closeSlideMenu() {
    
        UIView.animate(withDuration: self.slideDuration, animations: { () -> Void in
            self.slideMenuViewController.view.frame.origin = CGPoint(x: -self.slideMenuViewController.view.frame.width, y: 0)
            self.activeChild?.view.layer.transform = CATransform3DIdentity
        })
        
        // Get our transparentLayer.
        let transparentLayer = self.activeChild?.view.layer.sublayers!.filter({$0.name == self.transparentLayerKey})[0]
        
        // Create the opacity animation function
        let basicAnimation = CABasicAnimation(keyPath: "opacity")
        basicAnimation.duration = 0.35
        basicAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        basicAnimation.fromValue = transparentLayer?.opacity
        
        // animate to 0 if closed; animate to 0.5 if opening
        basicAnimation.toValue = 0
        transparentLayer!.opacity = 0
        
        // exec the animation function
        transparentLayer!.add(basicAnimation, forKey: self.transparentLayerAnimationKey)
        
        self.slideState = .closed
        (self.slideMenuViewController as! FWSlideMenuViewController).progressFinished(.closed)
    }
    
    open func displayViewController(_ vc: UIViewController) {
        if !self.childViewControllers.contains(vc) {
            self.addChildViewController(vc)
        }
        
        if self.activeChild == vc {
            // do nothing
        } else if self.activeChild == nil {
            self.view.addSubview(vc.view)
            self.view.bringSubview(toFront: self.slideMenuViewController.view)
            self.activeChild = vc
            self.closeSlideMenu()
        } else {
            self.flip(vc)
        }
        
    }
    
    open func displayViewController(index: Int) {
        self.displayViewController(self.childViewControllers[index])
    }
    
    override open func viewDidLoad() {
        
        self.screenEdgePanRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(recognizedSwipeGesture))
        self.screenEdgePanRecognizer?.edges = UIRectEdge.left
        self.view.addGestureRecognizer(self.screenEdgePanRecognizer!)
        
        self.panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(recognizedSwipeGesture))
        self.panRecognizer?.maximumNumberOfTouches = 1
        self.panRecognizer?.isEnabled = false
        self.view.addGestureRecognizer(self.panRecognizer!)
        
        self.tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(recognizedTapGesture))
        self.tapRecognizer?.numberOfTapsRequired = 1
        self.tapRecognizer?.numberOfTouchesRequired = 1
        self.tapRecognizer?.cancelsTouchesInView = false // otherwise slideMenu is untappable
        self.view.addGestureRecognizer(self.tapRecognizer!)
        
        self.slideMenuViewController.view.frame = CGRect(x: self.view.frame.width*(-self.slideOverFactor), y: 0, width: self.view.frame.width*self.slideOverFactor, height: self.view.frame.height)
        self.view.addSubview(self.slideMenuViewController.view)
        self.slideMenuViewController.view.layer.zPosition = 1000
        self.slideMenuViewController.didMove(toParentViewController: self)
        
        
        if childViewControllers.count != 0 {
            self.displayViewController(childViewControllers[0])
        } else {
            fatalError("You did not provide a ViewController at init")
        }
        
    }
    
    fileprivate func flip(_ to: UIViewController) {
        let old = self.activeChild!
        self.activeChild = to

        UIView.animate(withDuration: 0, animations: { () -> Void in
            self.activeChild?.view.layer.transform = CATransform3DMakeScale(self.zoomFactor,self.zoomFactor,self.zoomFactor)
        })
        
        // Get our transparentLayer.
        let transparentLayer = self.activeChild?.view.layer.sublayers!.filter({$0.name == self.transparentLayerKey})[0]
        transparentLayer!.opacity = 0.5
        
        self.view.addSubview(to.view)
        old.view.removeFromSuperview()
        self.view.bringSubview(toFront: self.slideMenuViewController.view)
        
        self.closeSlideMenu()
    }
    
    func recognizedTapGesture(_ recognizer:UITapGestureRecognizer) {
        if self.slideState == .opened && recognizer.location(in: self.view).x >= self.view.frame.size.width*self.slideOverFactor {
            self.closeSlideMenu()
        }
    }
    
    func recognizedSwipeGesture(_ recognizer:UIGestureRecognizer) {
        
        // If you move your finger from left to the very right you should see the fully ended animation. So lets stop the animation if your finger reached the slideMenuView's width

        
        // Stop do anything when you're moving your finger at the slideMenu. But start dragging if your finger is reaching the edge of slideMenuView
        if slideState == .opened && recognizer == self.panRecognizer && recognizer.location(in: self.view).x < (self.slideMenuViewController.view.frame.size.width-20) {
            return
        }
        
        switch recognizer.state {
        case .changed, .began, .possible: // The animation is going on or just started
            let touchPoint = recognizer.location(in: self.view).x
            self.moveSlideMenu(touchPoint-self.slideMenuViewController.view.frame.width)
            
        case .ended, .cancelled, .failed: // Put the animation to a defined state
            switch self.slideState {
            case .closing: // If the last known state was closing then close the menu
                self.closeSlideMenu()
            case .opening: // If the last known state was opening then open the menu
                self.openSlideMenu()
            default:
                break
            }
        }
        
    }
    
    fileprivate func moveSlideMenu(_ x: CGFloat) {
        
        func mapValue(_ x: CGFloat, in_min: CGFloat, in_max: CGFloat, out_min: CGFloat, out_max: CGFloat) -> CGFloat
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
            self.slideState = .opening
        } else {
            self.slideState = .closing
        }
        
        // Or did you even close/open?
        if point.x == 0 {
            self.slideState = .opened
            (self.slideMenuViewController as! FWSlideMenuViewController).progressFinished(.opened)
        } else if point.x == -self.slideMenuViewController.view.frame.width {
            self.slideState = .closed
            (self.slideMenuViewController as! FWSlideMenuViewController).progressFinished(.closed)
        } else { // We're in animation
            (self.slideMenuViewController as! FWSlideMenuViewController).progressChanged((currentProgress - 0.9) / 0.1) // convert our currentProgress to interval [0,1]
        }
        
        // Animate the slideMenuView
        self.slideMenuViewController.view.frame.origin = point
      
        
        // Animate all the rest
        self.animateActiveChild(currentProgress)
    }
    
    fileprivate func animateActiveChild(_ progress: CGFloat) {
        
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
        transparentLayer!.add(basicAnimation, forKey: self.transparentLayerAnimationKey)
        
        // Animate all the 3D stuff of the currently active VC
        if self.slideState == .opened {
            UIView.animate(withDuration: 0.1, animations: { 
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
