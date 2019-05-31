//
//  BaseViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import SafariServices
import RxSwift
import NotificationBannerSwift
import Reachability
import YandexMobileMetrica
import RxAppState

protocol ControllerType: class {
	associatedtype ViewModelType: ViewModelProtocol
	/// Configurates controller with specified ViewModelProtocol subclass
	///
	/// - Parameter viewModel: CPViewModel subclass instance to configure with
	func configure(with viewModel: ViewModelType)
	/// Factory function for view controller instatiation
	///
	/// - Parameter viewModel: View model object
	/// - Returns: View controller of concrete type
//	static func create(with viewModel: ViewModelType) -> UIViewController
}

protocol UIImpactFeedbackProtocol {

	var hardImpactFeedbackGenerator: UIImpactFeedbackGenerator { get }
	var lightImpactFeedbackGenerator: UIImpactFeedbackGenerator { get }

	func performLightImpact()

	func performHardImpact()
}

extension UIImpactFeedbackProtocol {

	func performLightImpact() {
		self.lightImpactFeedbackGenerator.prepare()
		self.lightImpactFeedbackGenerator.impactOccurred()
	}

	func performHardImpact() {
		self.hardImpactFeedbackGenerator.prepare()
		self.hardImpactFeedbackGenerator.impactOccurred()
	}
}

class BaseViewController: UIViewController, UIImpactFeedbackProtocol {

	let hardImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
	let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}

	override func viewDidLoad() {
		super.viewDidLoad()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.setNeedsStatusBarAppearanceUpdate()
	}
}

class BaseTableViewController: AccordionTableViewController, UIImpactFeedbackProtocol {

	let hardImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
	let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}

	override func viewDidLoad() {
		super.viewDidLoad()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.setNeedsStatusBarAppearanceUpdate()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		self.setNeedsStatusBarAppearanceUpdate()
	}
}

class BaseImagePickerController: UIImagePickerController {

	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.setNeedsStatusBarAppearanceUpdate()
	}
}

class BaseSafariViewController: SFSafariViewController {

	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.setNeedsStatusBarAppearanceUpdate()
	}
}

class BaseAlertController: UIAlertController {

	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.setNeedsStatusBarAppearanceUpdate()
	}
}

protocol TestnetToolbarProtocol where Self: UIViewController {
	var testnetToolbarView: UIView { get }
	var shouldShowTestnetToolbar: Bool { get }
	func didTapTestnetToolbar()
}

extension UIViewController: TestnetToolbarProtocol {

	var shouldShowTestnetToolbar: Bool {
		if let delegateProxy = UIApplication.shared.delegate as? RxApplicationDelegateProxy {
			if let appDele = delegateProxy.forwardToDelegate() as? AppDelegate {
				return appDele.isTestnet
			}
		}
		return false
	}

	var testnetToolbarView: UIView {
		let bottomView = UIView(frame: CGRect(x: 0,
																					y: 55.0,
																					width: view.bounds.width,
																					height: 1.0))
		bottomView.backgroundColor = UIColor(red: 189/255,
																				 green: 26/255,
																				 blue: 26/255,
																				 alpha: 1.0)

		let toolbarView = UIView(frame: CGRect(x: 0,
																					 y: 0,
																					 width: view.bounds.width,
																					 height: 56.0))
		toolbarView.backgroundColor = UIColor(red: 241/255,
																					green: 60/255,
																					blue: 60/255,
																					alpha: 1.0)
		toolbarView.addSubview(bottomView)

		let label = UILabel(frame: CGRect(x: 16.0,
																			y: 12.0,
																			width: 120.0,
																			height: 32.0))
		label.text = "THIS IS A TESTNET.\nNOT REAL MONEY!"
		label.font = UIFont.mediumFont(of: 12.0)
		label.textColor = .white
		label.numberOfLines = 0
		toolbarView.addSubview(label)

		let button = UIButton(frame: CGRect(x: view.bounds.width - 160 - 16,
																				y: 18.0,
																				width: 160.0,
																				height: 16.0))
		button.setAttributedTitle(NSAttributedString(string: "Download Mainnet App".uppercased().localized(),
																								 attributes: [
																									NSAttributedStringKey.font: UIFont.mediumFont(of: 12.0),
																									NSAttributedStringKey.foregroundColor: UIColor.white,
																									NSAttributedStringKey.underlineStyle: 1]),
															for: .normal)
		button.isUserInteractionEnabled = false
		button.setTitleColor(.white,
												 for: .normal)
		button.titleLabel?.font = UIFont.mediumFont(of: 12.0)
		toolbarView.addSubview(button)

		let tap = UITapGestureRecognizer(target: self, action: #selector(didTapTestnetToolbar))
		toolbarView.addGestureRecognizer(tap)
		return toolbarView
	}

	// MARK: -

	@objc func didTapTestnetToolbar() {
		let conf = Configuration()
		if let url = URL(string: conf.environment.appstoreURLString) {
			UIApplication.shared.open(url, options: [:]) { (res) in
				
			}
		}
	}
}
