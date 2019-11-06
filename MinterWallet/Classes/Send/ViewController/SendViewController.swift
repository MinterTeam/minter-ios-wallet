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
import AVFoundation

let sendViewControllerAddressNotification = NSNotification.Name(rawValue: "SendViewControllerAddressNotification")

class SendViewController:
	BaseViewController,
	ControllerType,
	UITableViewDelegate,
	UITableViewDataSource,
	SendPopupViewControllerDelegate,
	SentPopupViewControllerDelegate,
	TextViewTableViewCellDelegate {

	// MARK: - ControllerType

	var viewModel: SendViewModel!
	typealias ViewModelType = SendViewModel

	// MARK: - IBOutlet

	@IBOutlet weak var scanQRButton: UIBarButtonItem!
	@IBOutlet weak var txScanButton: UIBarButtonItem!
	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView.contentInset = UIEdgeInsets(top: 10.0,
																						left: 0.0,
																						bottom: 0.0,
																						right: 0.0)
			tableView.rowHeight = UITableViewAutomaticDimension
			tableView.estimatedRowHeight = 70
		}
	}

	// MARK: -

	var popupViewController: PopupViewController?

	private var disposeBag = DisposeBag()

	lazy var readerVC: QRCodeReaderViewController = {
		let builder = QRCodeReaderViewControllerBuilder {
			$0.reader = QRCodeReader(metadataObjectTypes: [.qr],
															 captureDevicePosition: .back)
			$0.showSwitchCameraButton = false
		}
		return QRCodeReaderViewController(builder: builder)
	}()

	// MARK: - Life cycle

	override func viewDidLoad() {
		super.viewDidLoad()

		registerCells()
		configure(with: viewModel)
		setUpTestnetToolbar()
		automaticallyAdjustsScrollViewInsets = true
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		viewModel.viewDidAppear()
		AnalyticsHelper.defaultAnalytics.track(event: .sendScreen)
	}

	// MARK: -

	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	func tableView(_ tableView: UITableView,
								 numberOfRowsInSection section: Int) -> Int {
		return viewModel.rowsCount(for: section)
	}

	func tableView(_ tableView: UITableView,
								 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let item = self.viewModel.cellItem(section: indexPath.section,
																						 row: indexPath.row),
			let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier,
																							 for: indexPath) as? BaseCell else {
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

			if nil != textViewCell as? SendPayloadTableViewCell {
				textViewCell.textView?.rx.text
					.subscribe(viewModel.input.payload).disposed(by: self.disposeBag)
			}
		}

		if let textField = cell as? AmountTextFieldTableViewCell {
			textField.amountDelegate = self
		}

		if let switchCell = cell as? SwitchTableViewCell {
			switchCell.delegate = self
		}
		return cell
	}
}

extension SendViewController {

	func configure(with viewModel: SendViewModel) {
		txScanButton
			.rx
			.tap
			.asDriver()
			.drive(viewModel.input.txScanButtonDidTap)
			.disposed(by: disposeBag)

		viewModel.output.errorNotification
			.asDriver(onErrorJustReturn: nil)
			.filter({ (notification) -> Bool in
				return nil != notification
			}).drive(onNext: { (notification) in
				let banner = NotificationBanner(title: notification?.title ?? "",
																				subtitle: notification?.text,
																				style: .danger)
				banner.show()
			}).disposed(by: disposeBag)

		viewModel
			.output
			.txErrorNotification
			.asDriver(onErrorJustReturn: nil)
			.drive(onNext: { [weak self] (notification) in
				guard nil != notification else {
					return
				}
				self?.popupViewController?.dismiss(animated: true, completion: nil)
				let banner = NotificationBanner(title: notification?.title ?? "",
																				subtitle: notification?.text,
																				style: .danger)
				banner.show()
			}).disposed(by: disposeBag)

		viewModel
			.output
			.popup
			.asDriver(onErrorJustReturn: nil)
			.drive(onNext: { [weak self] (popup) in
				if popup == nil {
					self?.popupViewController?.dismiss(animated: true, completion: nil)
					return
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
				} else {
					self?.showPopup(viewController: popup!,
													inPopupViewController: self!.popupViewController)
				}
			}).disposed(by: disposeBag)

		viewModel
			.sections
			.asObservable()
			.subscribe(onNext: { [weak self] (_) in
				self?.tableView.reloadData()
				guard let selectedPickerItem = self?.viewModel.selectedPickerItem() else {
					return
				}
				//Move to cell
				if let balanceCell = self?.tableView
					.cellForRow(at: IndexPath(item: 0, section: 0)) as? PickerTableViewCell {
					balanceCell.selectField.text = selectedPickerItem.title
				}
			}).disposed(by: disposeBag)

		if #available(iOS 11.0, *) {
			self.tableView.contentInset = UIEdgeInsets(top: self.shouldShowTestnetToolbar ? 70.0 : 10.0,
																								 left: 0.0,
																								 bottom: 0.0,
																								 right: 0.0)
		} else {
			NotificationCenter.default.rx
				.notification(NSNotification.Name.UIKeyboardWillHide)
				.subscribe(onNext: { (_) in
					self.tableView.contentInset = UIEdgeInsets(top: self.shouldShowTestnetToolbar ? 70.0 : 10.0,
																										 left: 0.0,
																										 bottom: 50.0,
																										 right: 0.0)
			}).disposed(by: disposeBag)
		}

		viewModel
			.output
			.showViewController
			.asDriver(onErrorJustReturn: nil)
			.drive(onNext: { [weak self] (viewController) in
				guard let viewController = viewController else { return }
				self?.tabBarController?.present(viewController, animated: true, completion: nil)
			}).disposed(by: disposeBag)

		txScanButton
			.rx
			.tap
			.asDriver()
			.drive(viewModel.input.txScanButtonDidTap)
			.disposed(by: disposeBag)

		txScanButton
			.rx
			.tap
			.subscribe({ [weak self] (_) in
				self?.present(self!.readerVC, animated: true, completion: nil)
			}).disposed(by: disposeBag)

		readerVC.completionBlock = { [weak self] (result: QRCodeReaderResult?) in
			self?.readerVC.stopScanning()
			self?.readerVC.dismiss(animated: true) {
				if let res = result?.value {
					self?.viewModel.input.didScanQR.onNext(res)
				}
			}
		}
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
		AnalyticsHelper.defaultAnalytics.track(event: .sendCoinsChooseCoinButton)
	}
}

extension SendViewController: PickerTableViewCellDataSource {
	func pickerItems(for cell: PickerTableViewCell) -> [PickerTableViewCellPickerItem] {
		return viewModel.accountPickerItems()
	}
}

extension SendViewController: ButtonTableViewCellDelegate {

	func buttonTableViewCellDidTap(_ cell: ButtonTableViewCell) {
		SoundHelper.playSoundIfAllowed(type: .bip)
		hardImpactFeedbackGenerator.prepare()
		hardImpactFeedbackGenerator.impactOccurred()
		AnalyticsHelper.defaultAnalytics.track(event: .sendCoinsSendButton)
		tableView.endEditing(true)
	}

	// MARK: - Validation

	func validate(cell: ValidatableCellProtocol) {}
}

extension SendViewController {

	// MARK: - SendPopupViewControllerDelegate

	func didFinish(viewController: SendPopupViewController) {
		SoundHelper.playSoundIfAllowed(type: .bip)
		lightImpactFeedbackGenerator.prepare()
		lightImpactFeedbackGenerator.impactOccurred()
		AnalyticsHelper.defaultAnalytics.track(event: .sendCoinPopupSendButton)
		viewModel.submitSendButtonTaped()
	}

	func didCancel(viewController: SendPopupViewController) {
		SoundHelper.playSoundIfAllowed(type: .cancel)
		AnalyticsHelper.defaultAnalytics.track(event: .sendCoinPopupCancelButton)
		viewController.dismiss(animated: true, completion: nil)
	}

	// MARK: - SentPopupViewControllerDelegate

	func didTapActionButton(viewController: SentPopupViewController) {
		SoundHelper.playSoundIfAllowed(type: .click)
		hardImpactFeedbackGenerator.prepare()
		hardImpactFeedbackGenerator.impactOccurred()
		AnalyticsHelper.defaultAnalytics.track(event: .sentCoinPopupViewTransactionButton)
		viewController.dismiss(animated: true) { [weak self] in
			if let url = self?.viewModel.lastTransactionExplorerURL() {
				let vc = BaseSafariViewController(url: url)
				self?.present(vc, animated: true) {}
			}
		}
	}

	func didTapSecondActionButton(viewController: SentPopupViewController) {
		SoundHelper.playSoundIfAllowed(type: .click)
		lightImpactFeedbackGenerator.prepare()
		lightImpactFeedbackGenerator.impactOccurred()
		AnalyticsHelper.defaultAnalytics.track(event: .sentCoinPopupShareTransactionButton)
		viewController.dismiss(animated: true) { [weak self] in
			if let url = self?.viewModel.lastTransactionExplorerURL() {
				let vc = ActivityRouter.activityViewController(activities: [url], sourceView: self!.view)
				self?.present(vc, animated: true, completion: nil)
			}
		}
	}

	func didTapSecondButton(viewController: SentPopupViewController) {
		SoundHelper.playSoundIfAllowed(type: .cancel)
		lightImpactFeedbackGenerator.prepare()
		AnalyticsHelper.defaultAnalytics.track(event: .sentCoinPopupCloseButton)
		viewController.dismiss(animated: true, completion: nil)
	}

	// MARK: -

	func heightDidChange(cell: TextViewTableViewCell) {
		// Disabling animations gives us our desired behaviour
		UIView.setAnimationsEnabled(false)
		/* These will causes table cell heights to be recaluclated,
		without reloading the entire cell */
		tableView.beginUpdates()
		tableView.endUpdates()
		// Re-enable animations
		UIView.setAnimationsEnabled(true)

		if let cell = cell as? SendPayloadTableViewCell {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				let textView = cell.textView
				if let startIndex = textView?.selectedTextRange?.start,
					let caretRect = textView?.caretRect(for: startIndex) {
					let newPosition = cell.textView.convert(caretRect, to: self.tableView).origin
					self.tableView.scrollRectToVisible(CGRect(x: 0,
																										y: newPosition.y,
																										width: self.tableView.bounds.width,
																										height: textView?.bounds.height ?? 0),
																						 animated: true)
				}
			}
		}
	}

	func heightWillChange(cell: TextViewTableViewCell) {}

	func didTapScanButton(cell: UsernameTableViewCell?) {
		AnalyticsHelper.defaultAnalytics.track(event: .sendCoinsQRButton)
		readerVC.delegate = self
		cell?.textView.becomeFirstResponder()
		readerVC.completionBlock = { (result: QRCodeReaderResult?) in
			if let indexPath = self.tableView.indexPath(for: cell!),
				let item = self.viewModel.cellItem(section: indexPath.section, row: indexPath.row) {
				cell?.textView.text = result?.value
			}
		}
		// Presents the readerVC as modal form sheet
		readerVC.modalPresentationStyle = .formSheet
		present(readerVC, animated: true, completion: nil)
	}
}

extension SendViewController: SwitchTableViewCellDelegate {
	func didSwitch(isOn: Bool, cell: SwitchTableViewCell) {}
}

extension SendViewController: ValidatableCellDelegate {

	func didValidateField(field: ValidatableCellProtocol?) {}

	func validate(field: ValidatableCellProtocol?, completion: (() -> ())?) {}
}

extension SendViewController: QRCodeReaderViewControllerDelegate {

	// MARK: - QRCodeReaderViewController Delegate Methods

	func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {}

	func reader(_ reader: QRCodeReaderViewController, didSwitchCamera newCaptureDevice: AVCaptureDeviceInput) {}

	func readerDidCancel(_ reader: QRCodeReaderViewController) {
		SoundHelper.playSoundIfAllowed(type: .cancel)
		reader.stopScanning()
		dismiss(animated: true, completion: nil)
	}
}

extension SendViewController: AmountTextFieldTableViewCellDelegate {

	func didTapUseMax() {
		self.view.endEditing(true)
		AnalyticsHelper.defaultAnalytics.track(event: .sendCoinsUseMaxButton)
	}
}

extension SendViewController {

	func setUpTestnetToolbar() {
		if self.shouldShowTestnetToolbar {
			self.tableView.contentInset = UIEdgeInsets(top: 70.0,
																								 left: 0.0,
																								 bottom: 0.0,
																								 right: 0.0)
			self.view.addSubview(self.testnetToolbarView)
		}
	}
}

extension SendViewController {

	private func registerCells() {
		tableView.register(UINib(nibName: "TextFieldTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "TextFieldTableViewCell")
		tableView.register(UINib(nibName: "UsernameTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "UsernameTableViewCell")
		tableView.register(UINib(nibName: "PayloadTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "PayloadTableViewCell")
		tableView.register(UINib(nibName: "AmountTextFieldTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "AmountTextFieldTableViewCell")
		tableView.register(UINib(nibName: "AddressTextViewTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "AddressTextViewTableViewCell")
		tableView.register(UINib(nibName: "PickerTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "PickerTableViewCell")
		tableView.register(UINib(nibName: "SwitchTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "SwitchTableViewCell")
		tableView.register(UINib(nibName: "TwoTitleTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "TwoTitleTableViewCell")
		tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "SeparatorTableViewCell")
		tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "ButtonTableViewCell")
		tableView.register(UINib(nibName: "BlankTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "BlankTableViewCell")
		tableView.register(UINib(nibName: "SendPayloadTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "SendPayloadTableViewCell")
	}
}
