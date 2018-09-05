//
//  ConvertCoinsViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 17/07/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift


class ConvertCoinsViewController: BaseViewController {
	
	let coinFormatter = CurrencyNumberFormatter.coinFormatter
	
	//MARK: - 
	
	@IBOutlet weak var approximately: UILabel!
	
	@IBOutlet weak var buttonActivityIndicator: UIActivityIndicatorView!
	
	@IBOutlet weak var getActivityIndicator: UIActivityIndicatorView!
	
	@IBOutlet weak var exchangeButton: DefaultButton!
	
	//MARK: -
	
	var disposableBag = DisposeBag()
	
	//MARK: -

	override func viewDidLoad() {
		super.viewDidLoad()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .default
	}
	
	//MARK: -
	
	func toggleTextFieldBorder(textField: UITextField?) {
		if textField?.isEditing == true {
			textField?.layer.borderColor = UIColor(hex: 0x502EC2)?.cgColor
		}
		else {
			textField?.layer.borderColor = UIColor(hex: 0x929292, alpha: 0.4)?.cgColor
		}
	}
	
	func setAppearance(for textField: UITextField) {
		textField.layer.cornerRadius = 8.0
		textField.layer.borderWidth = 2
		textField.layer.borderColor = UIColor(hex: 0x929292, alpha: 0.4)?.cgColor
		textField.rx.controlEvent([.editingDidBegin, .editingDidEnd])
			.asObservable()
			.subscribe(onNext: { [weak self] state in
				self?.toggleTextFieldBorder(textField: textField)
			}).disposed(by: disposableBag)
	}
	

}
