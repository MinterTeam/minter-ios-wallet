//
//  SpendCoinsViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 17/07/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift
import XLPagerTabStrip
import McPicker
import NotificationBannerSwift
import TPKeyboardAvoiding


class SpendCoinsViewController: ConvertCoinsViewController, IndicatorInfoProvider, UITextFieldDelegate {
	
	//MARK: -
	
	var viewModel = SpendCoinsViewModel()
	
	//MARK: - IBOutlet

	@IBOutlet weak var scrollView: TPKeyboardAvoidingScrollView!
	
	@IBOutlet weak var spendCoinTextField: ValidatableTextField! {
		didSet {
			setAppearance(for: spendCoinTextField)
			
			let imageView = UIImageView(image: UIImage(named: "textFieldSelectIcon"))
			let rightView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 10.0, height: 5.0))
			imageView.frame = CGRect(x: 0.0, y: 22.0, width: 10.0, height: 5.0)
			rightView.addSubview(imageView)
			
			spendCoinTextField?.rightView = rightView
			spendCoinTextField?.rightViewMode = .always
		}
	}
	
	@IBOutlet weak var spendAmountTextField: ValidatableTextField! {
		didSet {
			setAppearance(for: spendAmountTextField)
		}
	}
	
	@IBOutlet weak var getCoinTextField: ValidatableTextField! {
		didSet {
			setAppearance(for: getCoinTextField)
		}
	}
	
	@IBOutlet weak var getCoinActivityIndicator: UIActivityIndicatorView!
	
	@IBAction func didTapExchange(_ sender: Any) {
		viewModel.exchange()
	}
	
	@IBOutlet weak var amountErrorLabel: UILabel!
	
	@IBOutlet weak var getCoinErrorLabel: UILabel!
	
	@IBAction func didTapUseMax(_ sender: Any) {
		self.spendAmountTextField.text = viewModel.selectedBalanceString
		viewModel.spendAmount.value = viewModel.selectedBalanceString
	}
	
	//MARK: -

	override func viewDidLoad() {
		super.viewDidLoad()
		
		viewModel.spendCoin.asObservable().distinctUntilChanged().subscribe(onNext: { [weak self] (coin) in
			self?.spendCoinTextField.text = self?.viewModel.spendCoinText
		}).disposed(by: disposableBag)
		
		viewModel.isApproximatelyLoading.asObservable().distinctUntilChanged().subscribe(onNext: { [weak self] (val) in
			if val {
				self?.getActivityIndicator.isHidden = false
				self?.getActivityIndicator.startAnimating()
			}
			else {
				self?.getActivityIndicator.isHidden = true
				self?.getActivityIndicator.stopAnimating()
			}
		}).disposed(by: disposableBag)
		
		viewModel.approximately.asObservable().distinctUntilChanged().subscribe(onNext: { [weak self] (val) in
			self?.approximately.text = val
			
		}).disposed(by: disposableBag)
		
		viewModel.isLoading.asObservable().subscribe(onNext: { [weak self] (val) in
			if val {
				self?.exchangeButton.isEnabled = false
				self?.buttonActivityIndicator.startAnimating()
				self?.buttonActivityIndicator.isHidden = false
			}
			else {
				self?.exchangeButton.isEnabled = true
				self?.buttonActivityIndicator.stopAnimating()
				self?.buttonActivityIndicator.isHidden = true
			}
		}).disposed(by: disposableBag)
		
		viewModel.isButtonEnabled.distinctUntilChanged().subscribe(onNext: { [weak self] (val) in
			self?.exchangeButton.isEnabled = val
		}).disposed(by: disposableBag)
		
		viewModel.errorNotification.asObservable().filter({ (notification) -> Bool in
			return nil != notification
		}).subscribe(onNext: { (notification) in
			let banner = NotificationBanner(title: notification?.title ?? "", subtitle: notification?.text, style: .danger)
			banner.show()
		}).disposed(by: disposableBag)
		
		viewModel.successMessage.asObservable().filter({ (notification) -> Bool in
			return nil != notification
		}).subscribe(onNext: { (notification) in
			let banner = NotificationBanner(title: notification?.title ?? "", subtitle: notification?.text, style: .success)
			banner.show()
		}).disposed(by: disposableBag)
		
		viewModel.shouldClearForm.asObservable().filter({ (val) -> Bool in
			return val
		}).subscribe(onNext: { [weak self] (val) in
			self?.clearForm()
		}).disposed(by: disposableBag)
		
		Session.shared.allBalances.asObservable().subscribe(onNext: { [weak self] (val) in
			self?.spendCoinTextField.text = self?.viewModel.spendCoinText
			
			if self?.viewModel.hasMultipleCoins ?? false {
				self?.spendCoinTextField?.rightViewMode = .always
			}
			else {
				self?.spendCoinTextField?.rightViewMode = .never
			}
		}).disposed(by: disposableBag)
		
		viewModel.amountError.asObservable().subscribe(onNext: { (val) in
			self.amountErrorLabel.text = val
		}).disposed(by: disposableBag)
		
		viewModel.getCoinError.asObservable().subscribe(onNext: { (val) in
			self.getCoinErrorLabel.text = val
		}).disposed(by: disposableBag)
		
		viewModel.coinIsLoading.asObservable().subscribe(onNext: { (val) in
			if val {
				self.getCoinActivityIndicator.startAnimating()
				self.getCoinActivityIndicator.isHidden = false
			}
			else {
				self.getCoinActivityIndicator.stopAnimating()
				self.getCoinActivityIndicator.isHidden = true
			}
		}).disposed(by: disposableBag)

	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	//MARK: - UITextFieldDelegate
	
	func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		
		if textField == self.spendCoinTextField {
			scrollView.endEditing(true)
			showPicker()
			return false
		}
		
		return true
	}
	
	private func shouldShowPicker() -> Bool {
		return (viewModel.pickerItems().count) > 1
	}
	
	//MARK: -
	
	func clearForm() {
		self.spendAmountTextField.text = ""
		self.getCoinTextField.text = ""
	}
	
	func showPicker() {
		
		let items = viewModel.pickerItems()
		
		guard items.count > 0 else {
			return
		}
		
		let formatter = CurrencyNumberFormatter.decimalFormatter
		
		let data: [[String]] = [items.map({ (item) -> String in
			return (item.coin ?? "") + " (" + (formatter.string(from: (item.balance ?? 0) as NSNumber) ?? "") + ")"
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
				let balanceText = (formatter.string(from: (item.balance ?? 0) as NSNumber) ?? "")
				return (item.coin ?? "") + " (" + balanceText + ")" == coin
			}).first {
				self?.viewModel.selectedAddress = item.address
				self?.viewModel.selectedCoin = item.coin
			}
			
			self?.viewModel.spendCoin.value = coin
		}
	}
	
	//MARK: - IndicatorInfoProvider
	
	func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
		return IndicatorInfo(title: "SPEND".localized())
	}
	
	//MARK: - Validatable
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		
		var txtAfterUpdate = textField.text! as NSString
		txtAfterUpdate = txtAfterUpdate.replacingCharacters(in: range, with: string) as NSString
		
		if textField == self.spendAmountTextField {
			viewModel.spendAmount.value = txtAfterUpdate as String
		}
		else if textField == self.spendCoinTextField {
			viewModel.spendCoin.value = txtAfterUpdate as String
		}
		else if textField == getCoinTextField {
			viewModel.getCoin.value = txtAfterUpdate as String
		}
		viewModel.validateErrors()
		return true

	}

}
