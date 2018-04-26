//
//  PopupPopupViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 17/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

class PopupViewController: BaseViewController, CCMPlayNDropViewDelegate {

	//MARK: - IBOutlets
	
	
	@IBOutlet weak var popupTitle: UILabel!
	
	@IBOutlet weak var popupHeader: UIView! {
		didSet {
			popupHeader.roundCorners([.topLeft, .topRight], radius: 16.0)
		}
	}
	
	@IBOutlet weak var popupView: DroppableView!
	
	//MARK: -
	
	var viewModel: PopupViewModel?

	// MARK: Life cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		popupView.delegate = self
		
	}
	
	//MARK: -
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
	}
	
	//MARK: -
	
	func ccmPlayNDropViewDidFinishDismissAnimation(withDynamics view: CCMPlayNDropView!) {
		self.dismiss(animated: true, completion: nil)
	}

}
