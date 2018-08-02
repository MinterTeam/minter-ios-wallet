//
//  RootRootViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 04/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift
import Reachability
import NotificationBannerSwift


class RootViewController: UIViewController {
	
	var animationStart = false
	var shoudShowAnimateTransition = false
	
	enum AnimationType {
		case right
		case left
		case up
		case down
	}

	var viewModel = RootViewModel()
	
	let reachability = Reachability()!
	
	private let disposeBag = DisposeBag()

	// MARK: Life cycle

	override func viewDidLoad() {
		super.viewDidLoad()
		
		NotificationCenter.default.addObserver(self, selector: #selector(RootViewController.reachabilityChanged(_:)), name: Notification.Name.reachabilityChanged, object: nil)
		
		do {
			try reachability.startNotifier()
		} catch {
			print("could not start reachability notifier")
		}
	
		
		Observable.combineLatest(Session.shared.isLoggedIn.asObservable(), Session.shared.accounts.asObservable())/*.distinctUntilChanged({ (first, second) -> Bool in
			return first.0 == second.0 && first.1 == second.1
		})*/
		.subscribe(onNext: { (isLoggedIn, accounts) in
			
			if accounts.count > 0 || isLoggedIn {
				//has local accounts, show wallet
				let vc = Storyboards.Main.instantiateInitialViewController()
				
				self.showViewControllerWith(vc, usingAnimation: .up) {
					
				}
			}
			else {
				if let loginVC = LoginRouter.viewController(path: ["login"], param: [:]) {
					self.showViewControllerWith(loginVC, usingAnimation: .right, completion: {
						
					})
				}
			}
		}).disposed(by: disposeBag)
		
	}

@objc func reachabilityChanged(_ note: Notification) {
	
	let reachability = note.object as! Reachability
	
	switch reachability.connection {
	case .wifi:
		print("Reachable via WiFi")
	case .cellular:
		print("Reachable via Cellular")
	case .none:
//		print("Network not reachable")
		let banner = NotificationBanner(title: "Network is not reachable".localized(), subtitle: nil, style: .danger)
		banner.show()
	}
}

	func showViewControllerWith(_ newViewController: UIViewController, usingAnimation animationType: AnimationType, completion: (() -> ())?) {
		if animationStart {
			return
		}

		let currentViewController = self.childViewControllers.last
		
		if nil != currentViewController {
			guard newViewController.classForCoder != currentViewController!.classForCoder else {
				return
			}
		}
		
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
		UIView.animate(withDuration: duration, animations: { [weak currentViewController] () -> Void in
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
	
	override var childViewControllerForStatusBarHidden: UIViewController? {
		let vc = self.childViewControllers.last
		if let navigationVC = vc as? UINavigationController {
			return navigationVC.viewControllers.last
		}
		return vc
	}
	
	override var childViewControllerForStatusBarStyle: UIViewController? {
		let vc = self.childViewControllers.last
		if let navigationVC = vc as? UINavigationController {
			return navigationVC.viewControllers.last
		}
		return vc
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}

}
