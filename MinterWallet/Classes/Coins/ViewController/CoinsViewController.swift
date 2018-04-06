//
//  CoinsCoinsViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

class CoinsViewController: BaseViewController {

	//MARK: -
	
	@IBOutlet weak var usernameBarItem: UIBarButtonItem!
	
	@IBOutlet weak var usernameButton: UIButton!
	
	//MARK: -
	
	var viewModel = CoinsViewModel()

	// MARK: Life cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
//		self.usernameBarItem.setTitleTextAttributes([
//			NSAttributedStringKey.font: UIFont.boldFont(of: 14.0),
//			NSAttributedStringKey.foregroundColor: UIColor.white
//		], for: [.normal])
//		self.usernameBarItem.setTitleTextAttributes([
//			NSAttributedStringKey.font: UIFont.boldFont(of: 14.0),
//			NSAttributedStringKey.foregroundColor: UIColor.white
//			], for: [.highlighted])
//		self.usernameBarItem.imageInsets = UIEdgeInsetsMake(0, -15, 0, -15)
		self.usernameButton.titleLabel?.font = UIFont.boldFont(of: 14.0)
		self.usernameButton.setTitleColor(.white, for: .normal)
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .default
	}

}
