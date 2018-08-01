//
//  SendSendViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 13/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import NotificationBannerSwift
import RxSwift
import SafariServices
import SwiftValidator
import QRCodeReader
import AVFoundation


class SendViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource, SendPopupViewControllerDelegate, SentPopupViewControllerDelegate, CountdownPopupViewControllerDelegate, TextViewTableViewCellDelegate, AddressTextViewTableViewCellDelegate {
	
	//MARK: - IBOutlet
	
	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
			tableView.rowHeight = UITableViewAutomaticDimension
			tableView.estimatedRowHeight = 70
		}
	}
	
	//MARK: -
	
	var popupViewController: PopupViewController?
	
	var viewModel = SendViewModel()
	
	private var disposeBag = DisposeBag()
	
	lazy var readerVC: QRCodeReaderViewController = {
		let builder = QRCodeReaderViewControllerBuilder {
			$0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
			$0.showSwitchCameraButton = false
		}
		
		return QRCodeReaderViewController(builder: builder)
	}()

	//MARK: - Life cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		automaticallyAdjustsScrollViewInsets = false
		
		registerCells()
		
		viewModel.notifiableError.asObservable().filter({ (notification) -> Bool in
			return nil != notification
		}).subscribe(onNext: { (notification) in
			
			let banner = NotificationBanner(title: notification?.title ?? "", subtitle: notification?.text, style: .danger)
			banner.show()
		}).disposed(by: disposeBag)
		
		viewModel.txError.asObservable().subscribe(onNext: { [weak self] (notification) in
			guard nil != notification else {
				return
			}
			
			self?.popupViewController?.dismiss(animated: true, completion: nil)
			
			let banner = NotificationBanner(title: notification?.title ?? "", subtitle: notification?.text, style: .danger)
			banner.show()
		}).disposed(by: disposeBag)
		
		viewModel.showPopup.asObservable().subscribe(onNext: { [weak self] (popup) in
			if popup == nil {
				self?.popupViewController?.dismiss(animated: true, completion: nil)
				return
			}
			
			if let countdown = popup as? CountdownPopupViewController {
				countdown.delegate = self
			}
			
			if let sent = popup as? SentPopupViewController {
				sent.delegate = self
			}
			
			if let send = popup as? SendPopupViewController {
				self?.popupViewController = nil
				send.delegate = self
			}
			
			if self?.popupViewController == nil {
				self?.showPopup(viewController: popup!)
				self?.popupViewController = popup
			}
			else {
				self?.showPopup(viewController: popup!, inPopupViewController: self!.popupViewController)
			}
		}).disposed(by: disposeBag)

		viewModel.sections.asObservable().subscribe(onNext: { [weak self] (_) in
			
			self?.tableView.reloadData()
			
			guard let selectedPickerItem = self?.viewModel.selectedPickerItem() else {
				return
			}
			//Move to cell
			if let balanceCell = self?.tableView.cellForRow(at: IndexPath(item: 0, section: 0)) as? PickerTableViewCell {
				balanceCell.selectField.text = selectedPickerItem.title
			}
		}).disposed(by: disposeBag)
		
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		viewModel.createSections()
	}
	
	//MARK: -
	
	private func registerCells() {
		tableView.register(UINib(nibName: "TextFieldTableViewCell", bundle: nil), forCellReuseIdentifier: "TextFieldTableViewCell")
		tableView.register(UINib(nibName: "AmountTextFieldTableViewCell", bundle: nil), forCellReuseIdentifier: "AmountTextFieldTableViewCell")
		tableView.register(UINib(nibName: "AddressTextViewTableViewCell1", bundle: nil), forCellReuseIdentifier: "AddressTextViewTableViewCell1")
		tableView.register(UINib(nibName: "PickerTableViewCell", bundle: nil), forCellReuseIdentifier: "PickerTableViewCell")
		tableView.register(UINib(nibName: "SwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "SwitchTableViewCell")
		tableView.register(UINib(nibName: "TwoTitleTableViewCell", bundle: nil), forCellReuseIdentifier: "TwoTitleTableViewCell")
		tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil), forCellReuseIdentifier: "SeparatorTableViewCell")
		tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil), forCellReuseIdentifier: "ButtonTableViewCell")
		tableView.register(UINib(nibName: "BlankTableViewCell", bundle: nil), forCellReuseIdentifier: "BlankTableViewCell")
	}
	
	//MARK: -
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return viewModel.rowsCount(for: section)
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		guard let item = self.viewModel.cellItem(section: indexPath.section, row: indexPath.row), let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier, for: indexPath) as? BaseCell else {
			return UITableViewCell()
		}
		
		cell.configure(item: item)
		
		if let pickerCell = cell as? PickerTableViewCell {
			pickerCell.dataSource = self
			pickerCell.delegate = self
			
			pickerCell.updateRightViewMode()
		}
		
		if let buttonCell = cell as? ButtonTableViewCell {
			buttonCell.delegate = self
		}
		
		if let textViewCell = cell as? TextViewTableViewCell {
			textViewCell.delegate = self
			textViewCell.textView.rx.text.subscribe { newText in
				print(newText)
			}
			
			
		}
		
		if let textField = cell as? AmountTextFieldTableViewCell {
			textField.amountDelegate = self
		}
		
		if let addressCell = cell as? AddressTextViewTableViewCell1 {
			addressCell.addressDelegate = self
		}
		
		if let switchCell = cell as? SwitchTableViewCell {
			switchCell.delegate = self
		}
		
		var validatableCell = cell as? ValidatableCellProtocol
		validatableCell?.validateDelegate = self
		
		return cell
	}

}

extension SendViewController: PickerTableViewCellDelegate {
	
	func didFinish(with item: PickerTableViewCellPickerItem?) {
		if let item = item?.object as? AccountPickerItem {
			viewModel.accountPickerSelect(item: item)
		}
	}
	
	func willShowPicker() {
		tableView.endEditing(true)
	}
}

extension SendViewController: PickerTableViewCellDataSource {
	
	func pickerItems(for cell: PickerTableViewCell) -> [PickerTableViewCellPickerItem] {
		return viewModel.accountPickerItems()
	}
}

extension SendViewController : ButtonTableViewCellDelegate {
	
	func ButtonTableViewCellDidTap(_ cell: ButtonTableViewCell) {
		
		tableView.endEditing(true)
		
		viewModel.sendButtonTaped()
		
	}
	
	//MARK: - Validation
	
	func validate(cell: ValidatableCellProtocol) {
		//HACK: Some trouble with protocol?
		
		var validator: Validator?
		if let fieldCell = cell as? TextFieldTableViewCell {
			validator = fieldCell.validator
			validator?.validate { [fieldCell] (result) in
				guard result.count == 0 else {
					result.forEach({ (validation) in
						fieldCell.setInvalid(message: validation.1.errorMessage)
					})
					return
				}
				
				fieldCell.setDefault()
			}
		}
		else if let viewCell = cell as? TextViewTableViewCell {
			validator = viewCell.validator
			validator?.validate { [viewCell] (result) in
				guard result.count == 0 else {
					result.forEach({ (validation) in
						viewCell.setInvalid(message: validation.1.errorMessage)
					})
					return
				}
				
				viewCell.setDefault()
			}
		}
	}

}

extension SendViewController {
	
	func showPopup(viewController: PopupViewController, inPopupViewController: PopupViewController? = nil) {
		
		if nil != inPopupViewController {
			
			guard let currentViewController = (inPopupViewController?.childViewControllers.last as? PopupViewController) ?? inPopupViewController else {
				return
			}
			
			currentViewController.addChildViewController(viewController)
			
			viewController.willMove(toParentViewController: currentViewController)
			currentViewController.didMove(toParentViewController: viewController)
			
			currentViewController.view.addSubview(viewController.view)
			viewController.view.alpha = 0.0
			viewController.blurView.effect = nil
			
			guard let popupView = viewController.popupView else {
				return
			}
			
			popupView.frame = CGRect(x: currentViewController.view.frame.width, y: popupView.frame.origin.y, width: popupView.frame.width, height: popupView.frame.height)
			popupView.center = CGPoint(x: popupView.center.x, y: currentViewController.view.center.y)
			
			UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut, animations: {
				
				currentViewController.popupView.frame = CGRect(x: -currentViewController.popupView.frame.width, y: currentViewController.popupView.frame.origin.y, width: currentViewController.popupView.frame.width, height: currentViewController.popupView.frame.height)
				popupView.center = currentViewController.view.center
				viewController.view.alpha = 1.0
			})
			return
		}
		
		viewController.modalPresentationStyle = .overFullScreen
		viewController.modalTransitionStyle = .crossDissolve
		
		self.tabBarController?.present(viewController, animated: true, completion: nil)
	}
	
	//MARK: - SendPopupViewControllerDelegate
	
	func didFinish(viewController: SendPopupViewController) {
		guard let addressCell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? TextViewTableViewCell,
			let toAddress = addressCell.textView.text
			else {
				//error
				return
		}
		
		guard let amountCell = tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? TextFieldTableViewCell,
			let amount = Double(amountCell.textField.text?.replacingOccurrences(of: ",", with: ".") ?? "0") else {
				return
		}
		
		viewModel.submitSendButtonTaped()
	}
	
	func didCancel(viewController: SendPopupViewController) {
		viewController.dismiss(animated: true, completion: nil)
	}
	
	//MARK: - SentPopupViewControllerDelegate
	
	func didTapActionButton(viewController: SentPopupViewController) {
		viewController.dismiss(animated: true) { [weak self] in
			if let url = self?.viewModel.lastTransactionExplorerURL() {
				let vc = BaseSafariViewController(url: url)
				self?.present(vc, animated: true) {}
			}
		}
	}
	
	func didTapSecondButton(viewController: SentPopupViewController) {
		viewController.dismiss(animated: true, completion: nil)
	}

	//MARK: - CountdownPopupViewControllerDelegate
	
	func didFinishCounting(viewController: CountdownPopupViewController) {
		viewModel.countdownFinished.value = true
	}
	
	func didExeed10(viewController: CountdownPopupViewController) {
		viewModel.fakeCountdownFinished.value = true
		tableView.reloadData()
	}
	
	//MARK: -
	
	func heightDidChange(cell: TextViewTableViewCell) {
		// Disabling animations gives us our desired behaviour
		UIView.setAnimationsEnabled(false)
		/* These will causes table cell heights to be recaluclated,
		without reloading the entire cell */
		tableView.beginUpdates()
		tableView.endUpdates()
		// Re-enable animations
		UIView.setAnimationsEnabled(true)
	}
	
	func didTapScanButton() {
		// Retrieve the QRCode content
		// By using the delegate pattern
		readerVC.delegate = self
		
		// Or by using the closure pattern
		readerVC.completionBlock = { (result: QRCodeReaderResult?) in
			print(result)
		}
		
		// Presents the readerVC as modal form sheet
		readerVC.modalPresentationStyle = .formSheet
		present(readerVC, animated: true, completion: nil)
	}

}

extension SendViewController : SwitchTableViewCellDelegate {
	
	func didSwitch(isOn: Bool, cell: SwitchTableViewCell) {
		viewModel.isFreeTx.value = isOn
	}
	
}

extension SendViewController : ValidatableCellDelegate {
	
	func didValidateField(field: ValidatableCellProtocol?) {
		if let indexPath = tableView.indexPath(for: field as! UITableViewCell), let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) {
			viewModel.submitField(item: item, value: field?.validationText ?? "")
		}
		
	}
	
	func validate(field: ValidatableCellProtocol?, completion: (() -> ())?) {
		if let indexPath = tableView.indexPath(for: field as! UITableViewCell), let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) {
			if viewModel.validateField(item: item, value: field?.validationText ?? "") {
				
			}
		}
	}
}


extension SendViewController : QRCodeReaderViewControllerDelegate {
	// MARK: - QRCodeReaderViewController Delegate Methods
	
	func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
		reader.stopScanning()
		
		let addressCell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? TextViewTableViewCell
		addressCell?.textView.text = result.value
		addressCell?.textView.becomeFirstResponder()
		
		dismiss(animated: true, completion: nil)
	}
	
	//This is an optional delegate method, that allows you to be notified when the user switches the cameraName
	//By pressing on the switch camera button
	func reader(_ reader: QRCodeReaderViewController, didSwitchCamera newCaptureDevice: AVCaptureDeviceInput) {
		let cameraName = newCaptureDevice.device.localizedName
		print("Switching capturing to: \(cameraName)")
	}
	
	func readerDidCancel(_ reader: QRCodeReaderViewController) {
		reader.stopScanning()
		
		dismiss(animated: true, completion: nil)
	}
}

extension SendViewController : AmountTextFieldTableViewCellDelegate {
	
	func didTapUseMax() {
		
		let indexPath = IndexPath(row: 2, section: 0)
		guard let amountCell = tableView.cellForRow(at: indexPath) as? TextFieldTableViewCell else {
				return
		}
		
		if let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) {
		
			amountCell.textField.text = viewModel.selectedBalanceText
			
			viewModel.validateField(item: item, value: amountCell.textField.text ?? "")
		}
	}

}

