//
//  GetCoinsViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 17/07/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift
import XLPagerTabStrip
import NotificationBannerSwift
import McPicker
import TPKeyboardAvoiding


class GetCoinsViewController: ConvertCoinsViewController, IndicatorInfoProvider, UITextFieldDelegate {
	
	//MARK: -
	
	@IBOutlet weak var scrollView: TPKeyboardAvoidingScrollView!
	
	@IBOutlet weak var getAmountTextField: ValidatableTextField! {
		didSet {
			setAppearance(for: getAmountTextField)
		}
	}
	
	@IBOutlet weak var spendCoinTextField: ValidatableTextField! {
		didSet {
			setAppearance(for: spendCoinTextField)
		}
	}
	
	@IBAction func useMaxButtonDidTap(_ sender: Any) {
//		self.getAmountTextField.text = viewModel.spendCoinText
//		viewModel.getAmount.value =
	}
	
	@IBAction func didTapExchangeButton(_ sender: Any) {
		
		AnalyticsHelper.defaultAnalytics.track(event: .CovertGetExchangeButton, params: nil)
		
		vm.exchange()
	}
	
	@IBOutlet weak var getCoinActivityIndicator: UIActivityIndicatorView!
	
	@IBOutlet weak var getCoinErrorLabel: UILabel!
	
	@IBOutlet weak var amountErrorLabel: UILabel!
	
	// MARK: -
	
	var vm: GetCoinsViewModel {
		return viewModel as! GetCoinsViewModel
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		viewModel = GetCoinsViewModel()
		
		let imageView = UIImageView(image: UIImage(named: "textFieldSelectIcon"))
		let rightView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 10.0, height: 5.0))
		imageView.frame = CGRect(x: 0.0, y: 22.0, width: 10.0, height: 5.0)
		rightView.isUserInteractionEnabled = false
		rightView.addSubview(imageView)
		spendCoinTextField?.rightView = rightView
		spendCoinTextField?.rightViewMode = .always
		
		scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
		
		vm.spendCoin.asObservable().distinctUntilChanged().subscribe(onNext: { [weak self] (coin) in
			self?.spendCoinTextField.text = self?.vm.spendCoinText
		}).disposed(by: disposableBag)
		
		vm.isApproximatelyLoading.asObservable().distinctUntilChanged().subscribe(onNext: { [weak self] (val) in
			if val {
				self?.getActivityIndicator.isHidden = false
				self?.getActivityIndicator.startAnimating()
			}
			else {
				self?.getActivityIndicator.isHidden = true
				self?.getActivityIndicator.stopAnimating()
			}
		}).disposed(by: disposableBag)
		
		vm.approximately.asObservable().distinctUntilChanged().subscribe(onNext: { [weak self] (val) in
			self?.approximately.text = (val == nil ? "" : val)
		}).disposed(by: disposableBag)
		
		vm.isLoading.asObservable().subscribe(onNext: { [weak self] (val) in
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
		
		vm.isButtonEnabled.distinctUntilChanged().subscribe(onNext: { [weak self] (val) in
			self?.exchangeButton.isEnabled = val
		}).disposed(by: disposableBag)
		
		vm.errorNotification.asObservable().filter({ (notification) -> Bool in
			return nil != notification
		}).subscribe(onNext: { (notification) in
			let banner = NotificationBanner(title: notification?.title ?? "", subtitle: notification?.text, style: .danger)
			banner.show()
		}).disposed(by: disposableBag)
		
		vm.successMessage.asObservable().filter({ (notification) -> Bool in
			return nil != notification
		}).subscribe(onNext: { (notification) in
			let banner = NotificationBanner(title: notification?.title ?? "", subtitle: notification?.text, style: .success)
			banner.show()
		}).disposed(by: disposableBag)
		
		vm.shouldClearForm.asObservable().filter({ (val) -> Bool in
			return val
		}).subscribe(onNext: { [weak self] (val) in
			self?.clearForm()
		}).disposed(by: disposableBag)
		
		Session.shared.allBalances.asObservable().subscribe(onNext: { [weak self] (val) in
			self?.spendCoinTextField.text = self?.vm.spendCoinText
			if self?.vm.hasMultipleCoins ?? false {
				self?.spendCoinTextField?.rightViewMode = .always
			}
			else {
				self?.spendCoinTextField?.rightViewMode = .never
			}
		}).disposed(by: disposableBag)
		
		vm.amountError.asObservable().subscribe(onNext: { (val) in
			self.amountErrorLabel.text = val
		}).disposed(by: disposableBag)
		
		vm.getCoinError.asObservable().subscribe(onNext: { (val) in
			self.getCoinErrorLabel.text = val
		}).disposed(by: disposableBag)
		
		vm.coinIsLoading.asObservable().subscribe(onNext: { (val) in
			if val {
				self.getCoinActivityIndicator.isHidden = false
				self.getCoinActivityIndicator.startAnimating()
			}
			else {
				self.getCoinActivityIndicator.isHidden = true
				self.getCoinActivityIndicator.stopAnimating()
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
		else if textField == self.approximately {
			return false
		}
		
		return true
	}
	
	private func shouldShowPicker() -> Bool {
		return (vm.pickerItems().count) > 1
	}
	
	//MARK: -
	
	func clearForm() {
		self.getAmountTextField.text = ""
		self.getCoinTextField.text = ""
	}
	
	func showPicker() {
		
		let items = vm.pickerItems()
		
		guard items.count > 0 else {
			return
		}
		
//		let formatter = CurrencyNumberFormatter.decimalShortFormatter
		
		let data: [[String]] = [items.map({ (item) -> String in
			let balanceString = CurrencyNumberFormatter.formattedDecimal(with: (item.balance ?? 0), formatter: coinFormatter)
			return (item.coin ?? "") + " (" + balanceString + ")"
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
				let balanceString = CurrencyNumberFormatter.formattedDecimal(with: (item.balance ?? 0), formatter: self!.coinFormatter)
				return (item.coin ?? "") + " (" + balanceString + ")" == coin
			}).first {
				self?.vm.selectedAddress = item.address
				self?.vm.selectedCoin = item.coin
			}
			
			self?.vm.spendCoin.value = coin
		}
	}
	
	//MARK: - IndicatorInfoProvider
	
	func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
		return IndicatorInfo(title: "GET".localized())
	}
	
	//MARK: - Validatable
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		
		var txtAfterUpdate = textField.text ?? ""
		txtAfterUpdate = (txtAfterUpdate as NSString).replacingCharacters(in: range, with: string).uppercased()
		textField.text = txtAfterUpdate
		
		if textField == self.getAmountTextField {
			vm.getAmount.value = (txtAfterUpdate as String).replacingOccurrences(of: ",", with: ".")
		}
		else if textField == self.spendCoinTextField {
			vm.spendCoin.value = txtAfterUpdate as String
		}
		else if textField == getCoinTextField {
			vm.getCoin.value = txtAfterUpdate as String
			autocompleteView.perform(#selector(LUAutocompleteView.textFieldEditingChanged))
		}
		
		return false
	}

}
