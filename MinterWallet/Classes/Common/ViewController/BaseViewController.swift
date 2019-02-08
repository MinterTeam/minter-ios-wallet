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


class BaseViewController : UIViewController {
	
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



class BaseTableViewController : AccordionTableViewController {
	
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

class BaseImagePickerController : UIImagePickerController {
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.setNeedsStatusBarAppearanceUpdate()
	}
	
}

class BaseSafariViewController : SFSafariViewController {
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.setNeedsStatusBarAppearanceUpdate()
	}
	
}

class BaseAlertController : UIAlertController {
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.setNeedsStatusBarAppearanceUpdate()
	}
	
}
