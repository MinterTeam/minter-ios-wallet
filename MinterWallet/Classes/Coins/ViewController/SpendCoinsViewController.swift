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
import NotificationBannerSwift
import TPKeyboardAvoiding


class SpendCoinsViewController: ConvertCoinsViewController, IndicatorInfoProvider, UITextFieldDelegate {
	
	//MARK: -
	
	var vm: SpendCoinsViewModel {
		return viewModel as! SpendCoinsViewModel
	}
	
	private var formatter = CurrencyNumberFormatter.coinFormatter
	
	//MARK: - IBOutlet
	
	@IBOutlet weak var useMaxButton: UIButton!
	
	@IBOutlet weak var scrollView: TPKeyboardAvoidingScrollView!
	
	@IBOutlet weak var spendCoinTextField: ValidatableTextField! {
		didSet {
			setAppearance(for: spendCoinTextField)
			
			let imageView = UIImageView(image: UIImage(named: "textFieldSelectIcon"))
			let rightView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 10.0, height: 5.0))
			imageView.frame = CGRect(x: 0.0, y: 22.0, width: 10.0, height: 5.0)
			rightView.addSubview(imageView)
			rightView.isUserInteractionEnabled = false
			spendCoinTextField?.rightView = rightView
			spendCoinTextField?.rightViewMode = .always
		}
	}
	
	@IBOutlet weak var spendAmountTextField: ValidatableTextField! {
		didSet {
			setAppearance(for: spendAmountTextField)
		}
	}
	
//	@IBOutlet weak var getCoinTextField: ValidatableTextField! {
//		didSet {
//			setAppearance(for: getCoinTextField)
//		}
//	}
	
	@IBOutlet weak var getCoinActivityIndicator: UIActivityIndicatorView!
	
	@IBAction func didTapExchange(_ sender: Any) {
		
		SoundHelper.playSoundIfAllowed(type: .bip)
		
		hardImpactFeedbackGenerator.prepare()
		hardImpactFeedbackGenerator.impactOccurred()
		
		AnalyticsHelper.defaultAnalytics.track(event: .ConvertSpendExchangeButton, params: nil)
		
		vm.exchange()
	}
	
	@IBOutlet weak var amountErrorLabel: UILabel!
	
	@IBOutlet weak var getCoinErrorLabel: UILabel!
	
	@IBAction func didTapUseMax(_ sender: Any) {
		
		AnalyticsHelper.defaultAnalytics.track(event: .ConvertSpendUseMaxButton, params: nil)
		
		let balanceString = vm.selectedBalanceString?.replacingOccurrences(of: " ", with: "")
		self.spendAmountTextField.text = balanceString
		vm.spendAmount.value = balanceString
	}
	
	//MARK: -

	override func viewDidLoad() {
		super.viewDidLoad()
		
		viewModel = SpendCoinsViewModel()
		
		self.spendAmountTextField.rightPadding = useMaxButton.bounds.width
		
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
			self?.approximately.text = val
			
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
				self.getCoinActivityIndicator.startAnimating()
				self.getCoinActivityIndicator.isHidden = false
			}
			else {
				self.getCoinActivityIndicator.stopAnimating()
				self.getCoinActivityIndicator.isHidden = true
			}
		}).disposed(by: disposableBag)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		AnalyticsHelper.defaultAnalytics.track(event: .ConvertSpendScreen, params: nil)
		
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
		return (vm.pickerItems().count) > 1
	}
	
	//MARK: -
	
	func clearForm() {
		self.spendAmountTextField.text = ""
		self.getCoinTextField.text = ""
	}
	
	func showPicker() {
		
		let items = vm.pickerItems()
		
		guard items.count > 0 else {
			return
		}
		
//		let formatter = CurrencyNumberFormatter.decimalShortFormatter
		
		let data: [[String]] = [items.map({ (item) -> String in
			let balanceString = CurrencyNumberFormatter.formattedDecimal(with: (item.balance ?? 0), formatter: self.formatter)
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
				let balanceString = CurrencyNumberFormatter.formattedDecimal(with: (item.balance ?? 0), formatter: self!.formatter)
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
		return IndicatorInfo(title: "SPEND".localized())
	}
	
	//MARK: - Validatable
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		
		var txtAfterUpdate = textField.text ?? ""
		txtAfterUpdate = (txtAfterUpdate as NSString).replacingCharacters(in: range, with: string).uppercased()
		textField.text = txtAfterUpdate
		
		if textField == self.spendAmountTextField {
			vm.spendAmount.value = (txtAfterUpdate as String).replacingOccurrences(of: ",", with: ".")
		}
		else if textField == self.spendCoinTextField {
			vm.spendCoin.value = txtAfterUpdate as String
		}
		else if textField == getCoinTextField {
			vm.getCoin.value = txtAfterUpdate as String
			autocompleteView.perform(#selector(LUAutocompleteView.textFieldEditingChanged))
		}
		vm.validateErrors()
		return false
	}
}
