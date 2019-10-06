//
//  NewConvertViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 16/07/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import UIKit
import XLPagerTabStrip

class NewConvertViewController: ButtonBarPagerTabStripViewController {

	// MARK: -

	@IBOutlet weak var containerViewTopConstraint: NSLayoutConstraint!

	override func viewDidLoad() {

		self.title = "Convert Coins".localized()

		settings.style.selectedBarHeight = 3
		settings.style.buttonBarBackgroundColor = .white
		settings.style.buttonBarHeight = 48.0
		settings.style.buttonBarItemBackgroundColor = .white
		settings.style.buttonBarItemFont = UIFont.boldFont(of: 14.0)
		settings.style.buttonBarItemsShouldFillAvailiableWidth = true
		settings.style.buttonBarItemTitleColor = UIColor.mainColor()
		settings.style.selectedBarBackgroundColor = UIColor.mainColor()

		changeCurrentIndexProgressive = { (oldCell: ButtonBarViewCell?,
			newCell: ButtonBarViewCell?,
			progressPercentage: CGFloat,
			changeCurrentIndex: Bool, animated: Bool) -> Void in

			guard changeCurrentIndex == true else { return }

			oldCell?.label.textColor = .black
			newCell?.label.textColor = UIColor.mainColor()
		}

		super.viewDidLoad()
		
		let separatorView = UIView(frame: CGRect(x: 0, y: 47, width: view.bounds.width, height: 1.0))
		separatorView.backgroundColor = UIColor(hex: 0xE1E1E1)
		separatorView.translatesAutoresizingMaskIntoConstraints = false
		
		self.view.addSubview(separatorView)

		if self.shouldShowTestnetToolbar {
			self.containerViewTopConstraint.constant = 57
			self.view.addSubview(self.testnetToolbarView)

			buttonBarView.frame = CGRect(x: 0,
																	 y: 57,
																	 width: buttonBarView.bounds.width,
																	 height: buttonBarView.bounds.height)

			self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-104-[separator(1)]",
																															options: [],
																															metrics: nil,
																															views: ["separator" : separatorView]))
		} else {
			self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-47-[separator(1)]",
																															options: [],
																															metrics: nil,
																															views: ["separator" : separatorView]))
		}

		self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[separator]-0-|",
																														options: [],
																														metrics: nil,
																														views: ["separator" : separatorView]))
	}

	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}

	// MARK: -

	override public func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
		return [Storyboards.Convert.instantiateSpendCoinsViewController(), Storyboards.Convert.instantiateGetCoinsViewController()]
	}

}
