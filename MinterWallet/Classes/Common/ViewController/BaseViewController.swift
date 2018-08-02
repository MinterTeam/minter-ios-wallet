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


class BaseViewController : UIViewController {
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
//		try? DefaultReachabilityService().reachability.distinctUntilChanged({ (status1, status2) -> Bool in
//			return status1.reachable == status2.reachable
//		}).asObservable().subscribe(onNext: { (status) in
//			if !status.reachable {
//				let banner = NotificationBanner(title: "Network is not reachable".localized())
//				banner.show()
//			}
//		})
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.setNeedsStatusBarAppearanceUpdate()
	}

}



class BaseTableViewController : AccordionTableViewController {
	
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
