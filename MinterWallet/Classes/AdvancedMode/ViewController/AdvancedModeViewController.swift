//
//  AdvancedModeAdvancedModeViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 26/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit


class AdvancedModeViewController: BaseViewController {
	
	//MARK: - IBOutlet
	
	@IBOutlet weak var textView: GrowingDefaultTextView! {
		didSet {
			textView.textContainerInset = UIEdgeInsets(top: 10.0, left: 16.0, bottom: 16.0, right: 16.0)
		}
	}
	
	@IBAction func generateButtonDidTap(_ sender: Any) {
		
	}
	
	@IBAction func activateButtonDidTap(_ sender: Any) {
		if let rootVC = UIViewController.stars_topMostController() as? RootViewController {
			let vc = Storyboards.Main.instantiateInitialViewController()
			
			rootVC.showViewControllerWith(vc, usingAnimation: .up) {
				
			}
		}
	}
	
	//MARK: -

	var viewModel = AdvancedModeViewModel()

	//MARK: Life cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.hideKeyboardWhenTappedAround()
	}

}
