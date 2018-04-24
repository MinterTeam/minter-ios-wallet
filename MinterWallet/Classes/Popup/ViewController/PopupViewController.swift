//
//  PopupPopupViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 17/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

class PopupViewController: BaseViewController {

	//MARK: - IBOutlets
	
	
	@IBOutlet weak var popupTitle: UILabel!
	
	@IBOutlet weak var popupHeader: UIView! {
		didSet {
			popupHeader.roundCorners([.topLeft, .topRight], radius: 16.0)
		}
	}
	
	@IBOutlet weak var popupView: UIView! {
		didSet {
			popupView.roundCorners([.allCorners], radius: 16.0)
		}
	}
	
	//MARK: -
	
	var viewModel: PopupViewModel?

	// MARK: Life cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	//MARK: -
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
	}

}
