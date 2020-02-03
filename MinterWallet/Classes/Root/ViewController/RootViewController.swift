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
import MinterMy
import DeckTransition

class RootViewController: UIViewController, ControllerType {

	// MARK: - ControllerType

	var viewModel: RootViewModel! {
		didSet {
			tabbarVC.setViewControllers(viewModel.output.viewControllers(), animated: false)
		}
	}

	typealias ViewModelType = RootViewModel

	func configure(with viewModel: RootViewController.ViewModelType) {

		viewModel
			.output
			.shouldPresentPIN
			.asDriver(onErrorJustReturn: false)
			.drive(onNext: { [weak self] (present) in
				self?.shouldPresentPIN = present
			}).disposed(by: disposeBag)

		Observable.combineLatest(Session.shared.accounts.asObservable(),
														 Session.shared.isLoggedIn.asObservable(),
														 viewModel.output.shouldPresentPIN.asObservable()
			).skip(1)
			.asDriver(onErrorJustReturn: ([], false, false))
			.drive(onNext: { [weak self] (val) in
				self?.shouldPresentPIN = val.2
				if val.0.count == 0 {
					self?.nextStep(isLoggedIn: val.1)
				} else {
					self?.nextStep(accounts: val.0, isLoggedIn: val.1)
				}
			}).disposed(by: disposeBag)

		viewModel
			.output
			.shouldGoNextStep
			.withLatestFrom(Observable.combineLatest(Session.shared.isLoggedIn.asObservable(),
																							 Session.shared.accounts.asObservable()))
			.asDriver(onErrorJustReturn: (false, []))
			.drive(onNext: { [weak self] (val) in
				self?.nextStep(accounts: val.1, isLoggedIn: val.0)
			}).disposed(by: disposeBag)

		viewModel
			.output
			.openURL.filter({ (url) -> Bool in
				return url != nil
			})
			.asDriver(onErrorJustReturn: nil)
			.drive(onNext: { [weak self] (url) in
				self?.viewModel.input.didOpenURL.onNext(url)
				guard let url = url else { return }
				if let viewController = Router.viewController(by: url) {
          if (self?.presentedViewController) != nil {
						UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: {
							self?.show(viewController, sender: self)
						})
					} else {
            if let index = self?.tabbarVC.viewControllers?.firstIndex(where: { (controller) -> Bool in
              if let classForCoder = (controller as? UINavigationController)?.viewControllers.first?.classForCoder {
                return classForCoder == viewController.classForCoder
              }
              return false
            }) {
              self?.tabbarVC.selectedIndex = index
              return
            }

            let transitionDelegate = DeckTransitioningDelegate()
            viewController.transitioningDelegate = transitionDelegate
            viewController.modalPresentationStyle = .custom
            self?.present(viewController, animated: true, completion: nil)
					}
				} else {
					if url.host == "tx" || url.path.contains("tx") {
						BannerHelper.performErrorNotification(title: "Invalid transaction data".localized(), subtitle: nil)
					} else {
						BannerHelper.performErrorNotification(title: "Invalid deeplink".localized(), subtitle: nil)
					}
				}
			}).disposed(by: disposeBag)
	}

	// MARK: -

	var animationStart = false
	var shoudShowAnimateTransition = false

	enum AnimationType {
		case right
		case left
		case up
		case down
	}

	// MARK: -

	var shouldPresentPIN = false

	let reachability = Reachability()!

	private let disposeBag = DisposeBag()

	// MARK: Life cycle

	private var presenting = false

	override func viewDidLoad() {
		super.viewDidLoad()

		configure(with: viewModel)

		viewModel.didLoad()

		NotificationCenter.default.addObserver(self,
																					 selector: #selector(RootViewController.reachabilityChanged(_:)),
																					 name: Notification.Name.reachabilityChanged,
																					 object: nil)
		do {
			try reachability.startNotifier()
		} catch {
			print("could not start reachability notifier")
		}
	}

	@objc func reachabilityChanged(_ note: Notification) {
		guard let reachability = note.object as? Reachability else {
			return
		}

		switch reachability.connection {
		case .wifi:
			print("Reachable via WiFi")
		case .cellular:
			print("Reachable via Cellular")
		case .none:
			let banner = NotificationBanner(title: "Network is not reachable".localized(),
																			subtitle: nil,
																			style: .danger)
			banner.show()
		}
	}

	private var tabbarVC = Storyboards.Main.instantiateInitialViewController()

	func nextStep(accounts: [Account] = [], isLoggedIn: Bool) {

		if self.presenting {
			return
		}
		self.presenting = true

		if isLoggedIn || (!isLoggedIn && accounts.count > 0) {
			if shouldPresentPIN,
				let pinVC = PINRouter.defaultPINViewController() {

				func removePopupViewController(in viewController: UIViewController) {
					UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: {
						
					})
					UIApplication.shared.windows.first?.subviews.filter({ (view) -> Bool in
						return view as? McPicker != nil
					}).forEach({ (view) in
						(view as? McPicker)?.cancel()
					})
//
//					viewController.childViewControllers.forEach { (vc) in
//						if vc != viewController {
//							removePopupViewController(in: vc)
//						}
//					}
				}

				removePopupViewController(in: self)

				self.childViewControllers.first?.childViewControllers.forEach({ (vc) in
					vc.navigationController?.viewControllers.removeAll(where: { (val) -> Bool in
						return val as? PopupViewController != nil
					})
				})

				pinVC.delegate = self
				self.showViewControllerWith(pinVC, usingAnimation: .up) { [weak self] in
					self?.presenting = false
				}
			} else {
				//has local accounts, show wallet
				tabbarVC.selectedIndex = 0
				self.showViewControllerWith(tabbarVC, usingAnimation: .up) { [weak self] in
					self?.presenting = false
				}
			}
		} else {
			if let loginVC = LoginRouter.viewController(path: ["login"], param: [:]) {
				self.showViewControllerWith(loginVC,
																		usingAnimation: .right,
																		completion: { [weak self] in
					self?.presenting = false
				})
			}
		}
	}

	func showViewControllerWith(_ newViewController: UIViewController,
															usingAnimation animationType: AnimationType,
															completion: (() -> ())?) {
		if animationStart {
			completion?()
			return
		}

		let currentViewController = self.childViewControllers.last

		if nil != currentViewController {
			guard newViewController.classForCoder != currentViewController!.classForCoder else {
				completion?()
				return
			}
		}

		let width = self.view.frame.size.width
		let height = self.view.frame.size.height

		var previousFrame: CGRect?
		var nextFrame: CGRect?
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
		UIView.animate(withDuration: duration,
									 animations: { [weak currentViewController] () -> Void in
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

extension RootViewController: PINViewControllerDelegate {

	func PINViewControllerDidSucceed(controller: PINViewController, withPIN: String) {
		viewModel.input.pin.onNext(withPIN)

		Session.shared.checkPin(withPIN) { (res) in
			if !res {
				controller.shakeError()
			}
		}
	}

	func PINViewControllerDidSucceedWithBiometrics(controller: PINViewController) {}
}
