//
//  BaseViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import UIKit


class BaseViewController : UIViewController {
	
	var animationStart = false
	var shoudShowAnimateTransition = false
	
	enum AnimationType {
		case right
		case left
		case up
		case down
	}
	
	func showViewControllerWith(_ newViewController: UIViewController, usingAnimation animationType: AnimationType, completion: (() -> ())?) {
		if animationStart {
			return
		}
		
		let currentViewController = self.childViewControllers.last
		
		let width = self.view.frame.size.width
		let height = self.view.frame.size.height
		
		var previousFrame:CGRect?
		var nextFrame:CGRect?
		let initCurrentViewFrame = self.view.frame
		
		switch animationType {
		case .left:
			previousFrame = CGRect(x: width-1, y: 0.0, width: width, height: height)
			nextFrame = CGRect(x: -width, y: 0.0, width: width, height: height)
		
		case .right:
			previousFrame = CGRect(x: -width+1, y: 0.0, width: width, height: height)
			nextFrame = CGRect(x: width, y: 0.0, width: width, height: height)
		
		case .up:
			previousFrame = CGRect(x: 0.0, y: height-1, width: width, height: height)
			nextFrame = CGRect(x: 0.0, y: -height+1, width: width, height: height)
		
		case .down:
			previousFrame = CGRect(x: 0.0, y: -height+1, width: width, height: height)
			nextFrame = CGRect(x: 0.0, y: height-1, width: width, height: height)
		}
		
		self.addChildViewController(newViewController)
		
		newViewController.view.frame = previousFrame!
		self.view.addSubview(newViewController.view)
		
		var duration = 0.33
		if currentViewController == nil {
			duration = 0.0
		}
		
		animationStart = true
		UIView.animate(withDuration: duration, animations: { [weak currentViewController]() -> Void in
			newViewController.view.frame = initCurrentViewFrame
			if currentViewController != nil {
				currentViewController?.view.frame = nextFrame!
			}
		}, completion: { [weak self, currentViewController] (fihish: Bool) -> Void in

			if currentViewController != nil {
				currentViewController?.willMove(toParentViewController: self)
				currentViewController?.view.removeFromSuperview()
				currentViewController?.removeFromParentViewController()
			}
			
			self?.didMove(toParentViewController: newViewController)
			
			self?.shoudShowAnimateTransition = true
			self?.animationStart = false
			completion?()
		})
	}
}
