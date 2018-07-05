//
//  ConvertConvertViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 03/07/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift
import McPicker


class ConvertViewController: BaseViewController, UITextFieldDelegate {
	
	//MARK: - IBOutlet
	
	@IBOutlet weak var getCoinTextField: ValidatableTextField! {
		didSet {
			getCoinTextField.layer.cornerRadius = 8.0
			getCoinTextField.layer.borderWidth = 2
			getCoinTextField.layer.borderColor = UIColor(hex: 0x929292, alpha: 0.4)?.cgColor
		}
	}
	
	@IBOutlet weak var getCoinAmountTextField: UITextField! {
		didSet {
			getCoinAmountTextField.layer.cornerRadius = 8.0
			getCoinAmountTextField.layer.borderWidth = 2
			getCoinAmountTextField.layer.borderColor = UIColor(hex: 0x929292, alpha: 0.4)?.cgColor
		}
	}
	
	@IBOutlet weak var spendCoinTextField: ValidatableTextField! {
		didSet {
			spendCoinTextField.layer.cornerRadius = 8.0
			spendCoinTextField.layer.borderWidth = 2
			spendCoinTextField.layer.borderColor = UIColor(hex: 0x929292, alpha: 0.4)?.cgColor
		}
	}
	
	@IBOutlet weak var spendCoinAmountTextField: UITextField! {
		didSet {
			spendCoinAmountTextField.layer.cornerRadius = 8.0
			spendCoinAmountTextField.layer.borderWidth = 2
			spendCoinAmountTextField.layer.borderColor = UIColor(hex: 0x929292, alpha: 0.4)?.cgColor
		}
	}
	
	@IBOutlet weak var useMaxButton: DefaultButton!
	
	@IBOutlet weak var exchangeButton: DefaultButton!
	
	@IBAction func useMaxButtonDidTap(_ sender: Any) {
		self.spendCoinAmountTextField.text = String(viewModel.selectedBalance ?? 0)
	}
	
	//MARK: -

	var viewModel = ConvertViewModel()
	
	private var disposeBag = DisposeBag()

	//MARK: Life cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = viewModel.title
		
		getCoinTextField.rx.text.orEmpty.bind(to: viewModel.getCoin).disposed(by: disposeBag)
		
		viewModel.getAmount.asObservable().distinctUntilChanged({ (val1, val2) -> Bool in
			return val1 ?? 0 == val2 ?? 0
		}).subscribe(onNext: { (val) in
			self.getCoinAmountTextField.text = String(val ?? 0)
		}).disposed(by: disposeBag)
		
		getCoinAmountTextField.rx.text.orEmpty
		.map({ (val) -> Double? in
			return Double(val)
		}).bind(to: viewModel.getAmount).disposed(by: disposeBag)
		
		spendCoinTextField.rx.text.orEmpty.bind(to: viewModel.spendCoin).disposed(by: disposeBag)
		
		spendCoinAmountTextField.rx.text.orEmpty
		.map({ (val) -> Double? in
			return Double(val)
		}).bind(to: viewModel.spendAmount).disposed(by: disposeBag)
		
		viewModel.maxButtonTitle.asObservable().subscribe(onNext: { (val) in
			self.useMaxButton.setTitle(val, for: .normal)
		}).disposed(by: disposeBag)
		
		
	}
	
	//MARK: - UITextFieldDelegate
	
	func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		
//		guard self.shouldShowPicker() else {
//			return false
//		}
		
		if textField == self.spendCoinTextField {
		
			showPicker()
			return false
		}
		
		return true
	}
	
	private func shouldShowPicker() -> Bool {
		return (viewModel.pickerItems().count) > 1
	}
	
	//MARK: -
	
	func showPicker() {
		
		let items = viewModel.pickerItems()

		guard items.count > 0 else {
			return
		}

		let data: [[String]] = [items.map({ (item) -> String in
			return (item.coin ?? "") + " (" + String(item.balance ?? 0) + ")"
		})]

		let picker = McPicker(data: data)
		picker.toolbarButtonsColor = .white
		picker.toolbarDoneButtonColor = .white
		picker.toolbarBarTintColor = UIColor(hex: 0x4225A4)
		picker.toolbarItemsFont = UIFont.mediumFont(of: 16.0)
		picker.show { [weak self] (selected) in
			
			guard let coin = selected[0] else {
				return
			}
			
			if let item = items.filter({ (item) -> Bool in
				return (item.coin ?? "") + " (" + String(item.balance ?? 0) + ")" == coin
			}).first {
				self?.viewModel.selectedAddress = item.address
				self?.viewModel.selectedCoin = item.coin
			}
			
			self?.spendCoinAmountTextField.text = "0"
			self?.spendCoinTextField.text = coin
			self?.viewModel.spendCoin.value = coin
			
		}
	}

}
