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


class SendViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource, SendPopupViewControllerDelegate, SentPopupViewControllerDelegate, CountdownPopupViewControllerDelegate, TextViewTableViewCellDelegate {
	
	//MARK: - IBOutlet
	
	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
			tableView.rowHeight = UITableViewAutomaticDimension
			tableView.estimatedRowHeight = 70
		}
	}
	
	//MARK: -
	
	var popupViewController = Storyboards.Popup.instantiateInitialViewController()
	
	var viewModel = SendViewModel()
	
	private var disposeBag = DisposeBag()

	//MARK: - Life cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		registerCells()
		
		viewModel.notifiableError.asObservable().subscribe(onNext: { (notification) in
			guard nil != notification else {
				return
			}
			
			let banner = NotificationBanner(title: notification?.title ?? "", subtitle: notification?.text, style: .danger)
			banner.show()
		}).disposed(by: disposeBag)
		
		viewModel.txError.asObservable().subscribe(onNext: { [weak self] (notification) in
			guard nil != notification else {
				return
			}
			
			self?.popupViewController.dismiss(animated: true, completion: nil)
			
			let banner = NotificationBanner(title: notification?.title ?? "", subtitle: notification?.text, style: .danger)
			banner.show()
		}).disposed(by: disposeBag)
		
		viewModel.showPopup.asObservable().subscribe(onNext: { [weak self] (popup) in
			
			guard nil != popup else {
				return
			}
			
			if let countdown = popup as? CountdownPopupViewController {
				countdown.delegate = self
			}
			if let sent = popup as? SentPopupViewController {
				sent.delegate = self
			}
			
			self?.showPopup(viewController: popup!, inPopupViewController: self!.popupViewController)
		}).disposed(by: disposeBag)

		viewModel.sections.asObservable().subscribe(onNext: { [weak self] (_) in
			guard let selectedPickerItem = self?.viewModel.selectedPickerItem() else {
				return
			}
			//Move to cell
			if let balanceCell = self?.tableView.cellForRow(at: IndexPath(item: 0, section: 0)) as? PickerTableViewCell {
				balanceCell.selectField.text = selectedPickerItem.title
			}
		}).disposed(by: disposeBag)
		
	}
	
	//MARK: -
	
	private func registerCells() {
		tableView.register(UINib(nibName: "TextFieldTableViewCell", bundle: nil), forCellReuseIdentifier: "TextFieldTableViewCell")
		tableView.register(UINib(nibName: "TextViewTableViewCell", bundle: nil), forCellReuseIdentifier: "TextViewTableViewCell")
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
		}
		
		if let buttonCell = cell as? ButtonTableViewCell {
			buttonCell.delegate = self
		}
		
		if let textViewCell = cell as? TextViewTableViewCell {
			textViewCell.delegate = self
		}
		
		return cell
	}

}

extension SendViewController: PickerTableViewCellDelegate {
	
	func didFinish(with item: PickerTableViewCellPickerItem?) {
		if let item = item?.object as? AccountPickerItem {
			viewModel.accountPickerSelect(item: item)
		}
	}
}

extension SendViewController: PickerTableViewCellDataSource {
	
	func pickerItems(for cell: PickerTableViewCell) -> [PickerTableViewCellPickerItem] {
		return viewModel.accountPickerItems()
	}
}

extension SendViewController : ButtonTableViewCellDelegate {
	
	func ButtonTableViewCellDidTap(_ cell: ButtonTableViewCell) {
		
		guard let addressCell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? TextViewTableViewCell
			else {
				return
		}
		validate(cell: addressCell)
		
		guard let toAddress = addressCell.textView.text, toAddress.isValidAddress() else {
			return
		}
		
		guard let amountCell = tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? TextFieldTableViewCell else {
				return
		}
		
		validate(cell: amountCell)
		
		guard let amount = Double(amountCell.textField.text ?? "0") else {
			return
		}
		
		let vm = viewModel.sendViewModel(to: toAddress, amount: amount)

		popupViewController = Storyboards.Popup.instantiateInitialViewController()
		popupViewController.viewModel = vm
		popupViewController.delegate = self
		
		self.showPopup(viewController: popupViewController)
	}
	
	//MARK: - Validation
	
	func validate(cell: ValidatableCellProtocol) {
		let validator = cell.validator
		validator.validate { (result) in
			guard result.count == 0 else {
				result.forEach({ (validation) in
					cell.setInvalid(message: validation.1.errorMessage)
//					validation.1.errorLabel?.text =
				})
				return
			}
			
			cell.setDefault()
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
			let toAddress = addressCell.textView.text, toAddress.isValidAddress()
			else {
				//error
				return
		}
		
		guard let amountCell = tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? TextFieldTableViewCell,
			let amount = Double(amountCell.textField.text ?? "0") else {
				return
		}
		
		viewModel.send(to: toAddress, amount: amount)
	}
	
	func didCancel(viewController: SendPopupViewController) {
		viewController.dismiss(animated: true, completion: nil)
	}
	
	//MARK: - SentPopupViewControllerDelegate
	
	func didTapActionButton(viewController: SentPopupViewController) {
		viewController.dismiss(animated: true) { [weak self] in
			if let url = self?.viewModel.lastTransactionExplorerURL() {
				let vc = SFSafariViewController(url: url)
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

}
