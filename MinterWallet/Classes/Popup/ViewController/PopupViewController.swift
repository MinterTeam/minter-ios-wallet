//
//  PopupPopupViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 17/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift

protocol PopupViewControllerDelegate: class {
	func didDismissPopup(viewController: PopupViewController?)
}

class PopupViewController: BaseViewController, CCMPlayNDropViewDelegate {

	var disposeBag = DisposeBag()

	weak var popupViewControllerDelegate: PopupViewControllerDelegate?

	// MARK: - IBOutlets

	@IBOutlet weak var popupTitle: UILabel!
	@IBOutlet weak var popupHeader: UIView! {
		didSet {
			popupHeader.roundCorners([.topLeft, .topRight], radius: 16.0)
		}
	}
	@IBOutlet weak var popupView: DroppableView!
	@IBOutlet weak var blurView: UIVisualEffectView!

	// MARK: Life cycle

	override func viewDidLoad() {
		super.viewDidLoad()

		popupView.delegate = self
	}

	// MARK: -

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
	}

	// MARK: - CCMPlayNDropView

	func ccmPlayNDropViewDidFinishDismissAnimation(withDynamics view: CCMPlayNDropView!) {

	}

	func ccmPlayNDropViewWillStartDismissAnimation(withDynamics view: CCMPlayNDropView!) {
		if let deleg = popupViewControllerDelegate {
			deleg.didDismissPopup(viewController: self)
		} else {
			self.dismiss(animated: true, completion: nil)
		}
	}
}
