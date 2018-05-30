//
//  SentViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 30/05/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit


protocol SentPopupViewControllerDelegate : class {
	func didTapActionButton(viewController: SentPopupViewController)
	func didTapSecondButton(viewController: SentPopupViewController)
}


class SentPopupViewController: PopupViewController {

	weak var delegate: SentPopupViewControllerDelegate?
	
	//MARK: -
	
	@IBOutlet weak var receiverLabel: UILabel!
	@IBOutlet weak var avatarImageView: UIImageView!
	@IBOutlet weak var actionButton: DefaultButton!
	@IBOutlet weak var secondButton: DefaultButton!
	
	@IBAction func actionBtnDidTap(_ sender: Any) {
		delegate?.didTapActionButton(viewController: self)
	}
	
	@IBAction func secondButtonDidTap(_ sender: Any) {
		delegate?.didTapSecondButton(viewController: self)
	}
	
	
	//MARK: -
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		updateUI()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	//MARK: -
	
	private func updateUI() {
		
		guard let vm = viewModel as? SentPopupViewModel else {
			return
		}
		
		self.receiverLabel.text = vm.username
		self.avatarImageView.image = vm.avatarImage
		self.actionButton.setTitle(vm.actionButtonTitle, for: .normal)
		self.secondButton.setTitle(vm.secondButtonTitle, for: .normal)
		
	}

}
