//
//  AdvancedModeAdvancedModeViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 26/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit


protocol AdvancedModeViewControllerDelegate : class {
	func AdvancedModeViewControllerDidAddAccount()
}


class AdvancedModeViewController: BaseViewController {
	
	//MARK: -
	
	weak var delegate: AdvancedModeViewControllerDelegate?
	
	//MARK: - IBOutlet
	
	@IBOutlet weak var errorLabel: UILabel!
	
	@IBOutlet weak var textView: GrowingDefaultTextView! {
		didSet {
			textView.textContainerInset = UIEdgeInsets(top: 10.0, left: 16.0, bottom: 16.0, right: 16.0)
		}
	}
	
	@IBAction func generateButtonDidTap(_ sender: Any) {
		
	}
	
	@IBAction func activateButtonDidTap(_ sender: Any) {
		errorLabel.text = ""
		textView.setValid()
		
		let mnemonicText = textView.text.split(separator: " ")
		
		guard mnemonicText.count == 12 else {
			
			let err = type(of: viewModel).ValidationError.wrongMnemonic
			textView.setInvalid()
			errorLabel.text = viewModel.validationText(for: err)
			return
		}
		
		viewModel.saveAccount(id: -1, mnemonic: mnemonicText.joined(separator: " "))
		
		delegate?.AdvancedModeViewControllerDidAddAccount()
	}
	
	//MARK: -

	var viewModel = AdvancedModeViewModel()

	//MARK: Life cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.hideKeyboardWhenTappedAround()
	}
	
	//MARK: -
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		
		if segue.identifier == "showGenerate" {
			if let generate = segue.destination as? GenerateAddressViewController {
				generate.delegate = self
			}
		}
	}
}

extension AdvancedModeViewController : GenerateAddressViewControllerDelegate {
	
	func GenerateAddressViewControllerDelegateDidAddAccount() {
		self.delegate?.AdvancedModeViewControllerDidAddAccount()
	}
}

extension AdvancedModeViewController : UITextViewDelegate {
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		if text == "\n" {
			textView.resignFirstResponder()
		}
		return true
	}
}
