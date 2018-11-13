//
//  EmailEditViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 27/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import NotificationBannerSwift
import RxSwift


class EmailEditViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
	
	//MARK: - IBOutlets
	
	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView.tableFooterView = UIView()
			tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
		}
	}
	
	//MARK: -
	
	var viewModel = EmailEditViewModel()
	
	private var disposeBag = DisposeBag()
	
	//MARK: - ViewController
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = viewModel.title
		
		registerCells()
		
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
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		showKeyboard()
		
		AnalyticsHelper.defaultAnalytics.track(event: .EmailEditScreen, params: nil)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	//MARK: - TableView
	
	private func registerCells() {
		tableView.register(UINib(nibName: "TextFieldTableViewCell", bundle: nil), forCellReuseIdentifier: "TextFieldTableViewCell")
		tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil), forCellReuseIdentifier: "ButtonTableViewCell")
	}
	
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
		
		var validationCell = cell as? ValidatableCellProtocol
		validationCell?.validateDelegate = self
		
		var buttonCell = cell as? ButtonTableViewCell
		buttonCell?.delegate = self
		
		
		return cell
	}
	
	//MARK: -
	
	func showKeyboard() {
		if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TextFieldTableViewCell {
			cell.startEditing()
		}
	}
	
	//MARK: -
	
	func checkErrors() {
		if let errors = viewModel.validate(), let err = errors.first {
			if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TextFieldTableViewCell {
				cell.setInvalid(message: err)
			}
		}
		else {
			if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TextFieldTableViewCell {
				cell.setDefault()
			}
		}
	}
	
}

extension EmailEditViewController : ButtonTableViewCellDelegate {
	
	func ButtonTableViewCellDidTap(_ cell: ButtonTableViewCell) {
		
		SoundHelper.playSoundIfAllowed(type: .click)
		
		hardImpactFeedbackGenerator.prepare()
		hardImpactFeedbackGenerator.impactOccurred()
		
		tableView.endEditing(true)
		
		if let emailCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TextFieldTableViewCell, let email = emailCell.textField.text {
			
			self.viewModel.email.value = email
			
			checkErrors()
			
			if nil == viewModel.validate() {
				viewModel.update(email: email)
			}
		}
	}
	
}

extension EmailEditViewController : ValidatableCellDelegate {
	
	func validate(field: ValidatableCellProtocol?, completion: (() -> ())?) {
		
		self.viewModel.email.value = field?.validationText
		completion?()
	}

	func didValidateField(field: ValidatableCellProtocol?) {
		checkErrors()
	}

}
