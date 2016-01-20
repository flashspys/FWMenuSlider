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

public protocol FWSlideMenuControllerDelegate {
    func slideStateChanged(state: SlideState)
}

public protocol FWSlideMenuViewController {
    var controller: FWSlideMenuController? { get set }
    
    func progressChanged(progress: CGFloat)
    func progressFinished(state: SlideState)
}

public class FWSlideMenuController: UIViewController, UIGestureRecognizerDelegate {

    public var delegate: FWSlideMenuControllerDelegate?
    public var slideMenuViewController: FWDefaultSlideMenuViewController
    
    private var slideState: SlideState  = .Closed {
        didSet {
            self.delegate?.slideStateChanged(slideState)
            
            if slideState != .Closed {
                self.panRecognizer?.enabled = true
            } else {
                self.panRecognizer?.enabled = false
            }
        }
    }
    
    private var screenEdgePanRecognizer: UIScreenEdgePanGestureRecognizer?
    private var panRecognizer: UIPanGestureRecognizer?
    private var tapRecognizer: UITapGestureRecognizer?
    
    public var activeChild: UIViewController?
    
    public var slideOverFactor: CGFloat = 0.7
    public var slideDuration = 0.4
    let zoomFactor: CGFloat = 0.9
    
    public init(childs: [UIViewController], slideMenuController: FWDefaultSlideMenuViewController) {
        self.slideMenuViewController = slideMenuController
        super.init(nibName: nil, bundle: nil)
        self.slideMenuViewController.controller = self
        
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
        transparentLayer.name = "transparentLayer"
        childController.view.layer.addSublayer(transparentLayer)
        
        super.addChildViewController(childController)
        childController.view.frame = self.view.frame
    }
    
    public func openSlideMenu() {
        self.moveSlideMenu(0, animated: true)
    }
    
    private func flip(from: UIViewController, to: UIViewController) {
        /*
        to.view.layer.transform = CATransform3DMakeScale(self.zoomFactor,self.zoomFactor,self.zoomFactor)
        to.view.layer.sublayers!.filter({$0.name == "transparentLayer"})[0].opacity = 0.5
        */
        self.activeChild = to
        //TODO testen
        self.animateActiveChild(0.9, toState: .Opened)
        
        self.view.addSubview(to.view)
        from.view.removeFromSuperview()
        self.view.bringSubviewToFront(self.slideMenuViewController.view)
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
            self.flip(self.activeChild!, to: vc)
        }
        
        self.activeChild = vc
        moveSlideMenu(self.slideMenuViewController.view.frame.width * (-1), animated: true)
        
        
        
    }
    
    override public func viewDidLoad() {
        
        
        self.screenEdgePanRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "recognizedSwipeGesture:")
        self.screenEdgePanRecognizer?.edges = UIRectEdge.Left
        self.view.addGestureRecognizer(self.screenEdgePanRecognizer!)
        
        self.panRecognizer = UIPanGestureRecognizer(target: self, action: "recognizedSwipeGesture:")
        self.panRecognizer?.maximumNumberOfTouches = 1
        self.panRecognizer?.enabled = false
        self.view.addGestureRecognizer(self.panRecognizer!)
        
        self.tapRecognizer = UITapGestureRecognizer(target: self, action: "recognizedTapGesture:")
        self.tapRecognizer?.numberOfTapsRequired = 1
        self.tapRecognizer?.numberOfTouchesRequired = 1
        self.tapRecognizer?.cancelsTouchesInView = false
        self.view.addGestureRecognizer(self.tapRecognizer!)
        
        self.slideMenuViewController.view.frame = CGRect(x: self.view.frame.width*(-self.slideOverFactor), y: 0, width: self.view.frame.width*self.slideOverFactor, height: self.view.frame.height)
        self.view.addSubview(self.slideMenuViewController.view)
        self.slideMenuViewController.view.layer.zPosition = 1000
        self.slideMenuViewController.didMoveToParentViewController(self)
        
        
        if childViewControllers.count != 0 {
            self.displayViewController(childViewControllers[0])
        } else {
            fatalError("You did not provide a VC at init")
        }
        
    }
    
    func recognizedTapGesture(recognizer:UITapGestureRecognizer) {
        if self.slideState == .Opened && recognizer.locationInView(self.view).x >= self.view.frame.size.width*self.slideOverFactor {
            self.moveSlideMenu(-self.slideMenuViewController.view.frame.width, animated: true)
        }
    }
    
    func recognizedSwipeGesture(recognizer:UIGestureRecognizer) {
        
        if recognizer.locationInView(self.view).x >= self.slideMenuViewController.view.frame.size.width && recognizer == self.screenEdgePanRecognizer {
            self.moveSlideMenu(0, animated: true)
            return
        }
        
        if slideState == .Opened && recognizer == self.panRecognizer && recognizer.locationInView(self.view).x < (self.slideMenuViewController.view.frame.size.width-20) {
            return
        }
        
        switch recognizer.state {
        case .Changed,
        .Began,
        .Possible:
            let touchPoint = recognizer.locationInView(self.view).x
            self.moveSlideMenu(touchPoint-self.slideMenuViewController.view.frame.width, animated: false)
            
        case .Ended, .Cancelled, .Failed:
            switch self.slideState {
            case .Closing:
                self.moveSlideMenu(self.slideMenuViewController.view.frame.size.width * -1, animated: true)
            case .Opening:
                self.moveSlideMenu(0, animated: true)
            default:
                break
            }
        }
        
    }
    
    private func moveSlideMenu(x: CGFloat, animated: Bool) {
        
        func mapValue(x: CGFloat, in_min: CGFloat, in_max: CGFloat, out_min: CGFloat, out_max: CGFloat) -> CGFloat
        {
            return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
        }

        var point = CGPoint(x: 0, y: 0)
        point.x = min(0, x)
        point.x = max(-self.slideMenuViewController.view.frame.width, point.x)
        
        let currentProgress: CGFloat = max(mapValue(point.x, in_min: -self.slideMenuViewController.view.frame.width, in_max: 0, out_min: 1, out_max: zoomFactor), zoomFactor)
        
        if self.slideMenuViewController.view.frame.origin.x < point.x {
            self.slideState = .Opening
        } else {
            self.slideState = .Closing
        }
        
        if point.x == 0 {
            self.slideState = .Opened
            self.slideMenuViewController.progressFinished(.Opened)
        } else if point.x == -self.slideMenuViewController.view.frame.width {
            self.slideState = .Closed
            self.slideMenuViewController.progressFinished(.Closed)
        } else { // We're in animation
            self.slideMenuViewController.progressChanged((currentProgress - 0.9) / 0.1) // convert our currentProgress to %
        }
        
        if !animated {
            self.slideMenuViewController.view.frame.origin = point
        } else {
            UIView.animateWithDuration(self.slideDuration, animations: { () -> Void in
                self.slideMenuViewController.view.frame.origin = point
            })
        }
        
        self.animateActiveChild(currentProgress, toState: self.slideState)
    }
    
    func animateActiveChild(progress: CGFloat, toState state: SlideState) {
        
        let transparentLayer = self.activeChild?.view.layer.sublayers!.filter({$0.name == "transparentLayer"})[0]
        
        let basicAnimation = CABasicAnimation(keyPath: "opacity")
        basicAnimation.duration = 0.35
        basicAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        basicAnimation.fromValue = transparentLayer!.opacity
        if self.slideState == .Opened {
            basicAnimation.toValue = 0.5
            transparentLayer!.opacity = 0.5
        } else if self.slideState == .Closed {
            basicAnimation.toValue = 0
            transparentLayer!.opacity = 0
        } else {
            basicAnimation.duration = 0
            basicAnimation.toValue = Float(0.5-(progress-0.9)*(0.5)/(0.1))
            transparentLayer!.opacity = Float(0.5-(progress-0.9)*(0.5)/(0.1))
        }
        
        transparentLayer!.addAnimation(basicAnimation, forKey: "transparentAnimation")
        
        
        if state == .Opened || state == .Closed {
            UIView.animateWithDuration(0.4, animations: { () -> Void in
                if self.slideState == .Opened {
                    self.activeChild?.view.layer.transform = CATransform3DMakeScale(self.zoomFactor,self.zoomFactor,self.zoomFactor)
                } else if self.slideState == .Closed {
                    self.activeChild?.view.layer.transform = CATransform3DIdentity
                }
            })
            
        } else {
            
            var transform: CATransform3D = CATransform3DIdentity;
            transform.m34 = 1.0 / 600.0;
            transform = CATransform3DRotate(transform, 1-progress, 0, 1, 0)
            transform = CATransform3DScale(transform, progress, progress, progress)
            self.activeChild?.view.layer.transform = transform;
            
        }
    }
    
    
    
    
}
