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
import NotificationBannerSwift


class ConvertViewController: BaseViewController, UITextFieldDelegate {
	
	//MARK: - IBOutlet
	
	@IBOutlet weak var getCoinTextField: ValidatableTextField! {
		didSet {
			getCoinTextField.layer.cornerRadius = 8.0
			getCoinTextField.layer.borderWidth = 2
			getCoinTextField.layer.borderColor = UIColor(hex: 0x929292, alpha: 0.4)?.cgColor
			getCoinTextField.rx.controlEvent([.editingDidBegin, .editingDidEnd])
				.asObservable()
				.subscribe(onNext: { state in
					self.toggleTextFieldBorder(textField: self.getCoinTextField)
				})
				.disposed(by: disposeBag)
		}
	}
	
	@IBOutlet weak var getCoinAmountTextField: UITextField! {
		didSet {
			getCoinAmountTextField.layer.cornerRadius = 8.0
			getCoinAmountTextField.layer.borderWidth = 2
			getCoinAmountTextField.layer.borderColor = UIColor(hex: 0x929292, alpha: 0.4)?.cgColor
			getCoinAmountTextField.rx.controlEvent([.editingDidBegin, .editingDidEnd])
				.asObservable()
				.subscribe(onNext: { state in
					self.toggleTextFieldBorder(textField: self.getCoinAmountTextField)
				})
				.disposed(by: disposeBag)
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
			spendCoinAmountTextField.rx.controlEvent([.editingDidBegin, .editingDidEnd])
			.asObservable()
			.subscribe(onNext: { state in
				self.toggleTextFieldBorder(textField: self.spendCoinAmountTextField)
			})
			.disposed(by: disposeBag)
		}
	}
	
	func toggleTextFieldBorder(textField: UITextField?) {
		if textField?.isEditing == true {
			textField?.layer.borderColor = UIColor(hex: 0x502EC2)?.cgColor
		}
		else {
			textField?.layer.borderColor = UIColor(hex: 0x929292, alpha: 0.4)?.cgColor
		}
	}
	
	@IBOutlet weak var useMaxButton: DefaultButton!
	
	@IBOutlet weak var exchangeButton: DefaultButton!
	
	@IBAction func useMaxButtonDidTap(_ sender: Any) {
		self.spendCoinAmountTextField.text = String(viewModel.selectedBalance ?? 0)
		viewModel.spendAmount.value = viewModel.selectedBalance ?? 0
	}
	
	@IBAction func exchangeButtonDidTap(_ sender: Any) {
		viewModel.convert()
	}
	
	@IBOutlet weak var coinActivityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var getAmountActivityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var spendAmountActivityIndicator: UIActivityIndicatorView!
	//MARK: -
	
	var formatter = CurrencyNumberFormatter.coinFormatter

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
			if nil == val {
				self.spendCoinAmountTextField.text = nil
				return
			}
			
			guard !self.getCoinAmountTextField.isFirstResponder else {return}
			
			self.getCoinAmountTextField.text = self.formatter.string(from: NSNumber(value: val ?? 0.0))//String(format: "%.5f", val ?? 0.0)
		}).disposed(by: disposeBag)
		
		getCoinAmountTextField.rx.text.orEmpty.debug()
		.map({ (val) -> Double? in
			return Double(val)
		}).bind(to: viewModel.getAmount).disposed(by: disposeBag)
		
		spendCoinTextField.rx.text.orEmpty.bind(to: viewModel.spendCoin).disposed(by: disposeBag)
		
		spendCoinAmountTextField.rx.text.orEmpty
		.map({ (val) -> Double? in
			return Double(val)
		}).bind(to: viewModel.spendAmount).disposed(by: disposeBag)
		
		viewModel.spendAmount.asObservable().subscribe(onNext: { (val) in
			if nil == val {
				self.spendCoinAmountTextField.text = nil
				return
			}
			guard !self.spendCoinAmountTextField.isFirstResponder else {return}
			self.spendCoinAmountTextField.text = self.formatter.string(from: NSNumber(value: val ?? 0.0))//String(format: "%.5f", val ?? 0.0)
		}).disposed(by: disposeBag)
		
		viewModel.maxButtonTitle.asObservable().subscribe(onNext: { (val) in
			self.useMaxButton.setTitle(val, for: .normal)
		}).disposed(by: disposeBag)
		
		if let coin = viewModel.selectedCoin {
			let balance = viewModel.selectedBalance ?? 0
			self.spendCoinTextField.text = coin + " (" + String(format: "%.5f", balance) + ")"
		}
		
		viewModel.isButtonAvailableObservable.bind(to: exchangeButton.rx.isEnabled).disposed(by: disposeBag)
		
		viewModel.coinIsLoading.asObservable().subscribe(onNext: { (val) in
			if val {
				self.coinActivityIndicator.startAnimating()
				self.coinActivityIndicator.isHidden = false
			}
			else {
				self.coinActivityIndicator.stopAnimating()
				self.coinActivityIndicator.isHidden = true
			}
		}).disposed(by: disposeBag)
		
		viewModel.getAmountIsLoading.asObservable().subscribe(onNext: { (val) in
			if val {
				self.getAmountActivityIndicator.startAnimating()
				self.getAmountActivityIndicator.isHidden = false
			}
			else {
				self.getAmountActivityIndicator.stopAnimating()
				self.getAmountActivityIndicator.isHidden = true
			}
		}).disposed(by: disposeBag)
		
		viewModel.spendAmountIsLoading.asObservable().subscribe(onNext: { (val) in
			if val {
				self.spendAmountActivityIndicator.startAnimating()
				self.spendAmountActivityIndicator.isHidden = false
			}
			else {
				self.spendAmountActivityIndicator.stopAnimating()
				self.spendAmountActivityIndicator.isHidden = true
			}
		}).disposed(by: disposeBag)
		
		viewModel.errorNotification.asObservable().filter({ (notification) -> Bool in
			return nil != notification
		}).subscribe(onNext: { (notification) in
			let banner = NotificationBanner(title: notification?.title ?? "", subtitle: notification?.text, style: .danger)
			banner.show()
		}).disposed(by: disposeBag)
		
		viewModel.successMessage.asObservable().filter({ (notification) -> Bool in
			return nil != notification
		}).subscribe(onNext: { (notification) in
			let banner = NotificationBanner(title: notification?.title ?? "", subtitle: notification?.text, style: .success)
			banner.show()
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
			
			self?.spendCoinAmountTextField.text = "0.0"
			self?.spendCoinTextField.text = coin
			self?.viewModel.spendCoin.value = coin
			
		}
	}

}
