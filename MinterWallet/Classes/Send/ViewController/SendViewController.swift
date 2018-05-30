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


class SendViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource, SendPopupViewControllerDelegate, SentPopupViewControllerDelegate {
	
	//MARK: - IBOutlet
	
	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
		}
	}
	
	//MARK: -
	
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
		
		viewModel.successfullySentViewModel.asObservable().subscribe(onNext: { [weak self] (vm) in
			guard nil != vm else {
				return
			}
			
			let popup = Storyboards.Popup.instantiateSentPopupViewController()
			popup.viewModel = vm
			popup.delegate = self
			
			self?.showPopup(viewController: popup)
			
		}).disposed(by: disposeBag)
		
	}
	
	//MARK: -
	
	private func registerCells() {
		tableView.register(UINib(nibName: "TextFieldTableViewCell", bundle: nil), forCellReuseIdentifier: "TextFieldTableViewCell")
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
		return viewModel.accountPickerItems().map({ (account) -> PickerTableViewCellPickerItem in
			return PickerTableViewCellPickerItem(title: account.title, object: account)
		})
	}

}


extension SendViewController : ButtonTableViewCellDelegate {
	
	func ButtonTableViewCellDidTap(_ cell: ButtonTableViewCell) {
		
		guard let addressCell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? TextFieldTableViewCell,
			let toAddress = addressCell.textField.text, toAddress.isValidAddress()
			else {
				//error
				return
		}
		
		guard let amountCell = tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? TextFieldTableViewCell,
			let amount = Double(amountCell.textField.text ?? "0") else {
				return
		}
		
		let vm = viewModel.sendViewModel(to: toAddress, amount: amount)

		let popup = Storyboards.Popup.instantiateInitialViewController()
		popup.viewModel = vm
		popup.delegate = self
		
		self.showPopup(viewController: popup)
	}
	
	func showPopup(viewController: UIViewController) {
		viewController.modalPresentationStyle = .overFullScreen
		viewController.modalTransitionStyle = .crossDissolve
		
		self.tabBarController?.present(viewController, animated: true, completion: nil)
	}
	
	//MARK: - SendPopupViewControllerDelegate
	
	func didFinish(viewController: SendPopupViewController) {
		guard let addressCell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? TextFieldTableViewCell,
			let toAddress = addressCell.textField.text, toAddress.isValidAddress()
			else {
				//error
				return
		}
		
		guard let amountCell = tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? TextFieldTableViewCell,
			let amount = Double(amountCell.textField.text ?? "0") else {
				return
		}
		
		viewModel.send(to: toAddress, amount: amount)
		
		let countdownVM = CountdownPopupViewModel()
		countdownVM.popupTitle = "Please wait"
		countdownVM.unit = (one: "second", two: "seconds", other: "seconds")
		countdownVM.count = 20
		countdownVM.desc1 = "Coins will be received in"
		countdownVM.desc2 = "Too long? You can make a faster transaction for 0.00000001 BIP"
		countdownVM.buttonTitle = "Express transaction"
		
		let countdownVC = Storyboards.Popup.instantiateCountdownPopupViewController()
		countdownVC.viewModel = countdownVM
		
		self.showPopup(viewController: countdownVC)
	}
	
	func didCancel(viewController: SendPopupViewController) {
		
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

}
