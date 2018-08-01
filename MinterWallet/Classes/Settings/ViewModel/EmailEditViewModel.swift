//
//  EmailEditViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 27/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import MinterCore
import MinterMy
import RxSwift


class EmailEditViewModel: BaseViewModel {
	
	//MARK: -
	
	var profileManager: ProfileManager?
	
	var errorNotification = Variable<NotifiableError?>(nil)
	
	var successMessage = Variable<NotifiableSuccess?>(nil)
	
	var disposeBag = DisposeBag()
	
	//MARK: -
	
	private var isLoading = Variable(false)
	
	var email = Variable<String?>(Session.shared.user.value?.email)
	
	var isButtonEnabled = Variable(false)
	var state = Variable(TextFieldTableViewCell.State.default)
	
	//MARK: -
	
	override init() {
		super.init()
		
		createSection()
		
		email.asObservable().distinctUntilChanged().subscribe(onNext: { [weak self] (val) in
			
			if val?.isValidEmail() == true {
				self?.isButtonEnabled.value = true
				self?.state.value = .default
			}
			else {
				if nil == self?.email.value || self?.email.value == "" {
					self?.state.value = .default
				}
				else {
					self?.state.value = .invalid(error: "EMAIL IS INCORRECT".localized())
				}
				self?.isButtonEnabled.value = false
			}
			
			if (self?.email.value ?? "") == (Session.shared.user.value?.email ?? "") {
				self?.isButtonEnabled.value = false
			}
		}).disposed(by: disposeBag)
	}
	
	//MARK: -
	
	var title: String {
		get {
			return "Email".localized()
		}
	}
	
	//MARK: - TableView
	
	var sections: [BaseTableSectionItem] = []
	
	func createSection() {
		
		var section = BaseTableSectionItem(header: "", items: [])
		
		let email = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: "TextFieldTableViewCell_Email")
		email.title = "EMAIL (OPTIONAL *)".localized()
		email.value = Session.shared.user.value?.email
		email.keyboardType = .emailAddress
		email.stateObservable = state.asObservable()
		
		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell", identifier: "ButtonTableViewCell")
		button.buttonPattern = "purple"
		button.title = "SAVE".localized()
		button.isLoadingObserver = isLoading.asObservable()
		button.isButtonEnabledObservable = isButtonEnabled.asObservable()
		button.isButtonEnabled = false
		
		section.items = [email, button]
		
		sections.append(section)
	}
	
	func section(index: Int) -> BaseTableSectionItem? {
		return sections[safe: index]
	}
	
	func sectionsCount() -> Int {
		return sections.count
	}
	
	func rowsCount(for section: Int) -> Int {
		return sections[safe: section]?.items.count ?? 0
	}
	
	func cellItem(section: Int, row: Int) -> BaseCellItem? {
		return sections[safe: section]?.items[safe: row]
	}
	
	//MARK: -
	
	func update(email: String) {
		
		guard email.isValidEmail() && email != (Session.shared.user.value?.email ?? "") else {
			return
		}
		
		guard let client = APIClient.withAuthentication(), let user = Session.shared.user.value else {
			self.errorNotification.value = NotifiableError(title: "Something went wrong".localized(), text: nil)
			return
		}
		
		isLoading.value = true
		
		if nil == profileManager {
			profileManager = ProfileManager(httpClient: client)
		}
		
		user.email = email
		
		profileManager?.updateProfile(user: user, completion: { [weak self] (updated, error) in
			
			self?.isLoading.value = false
			
			guard nil == error else {
				self?.errorNotification.value = NotifiableError(title: "Profile can't be saved".localized(), text: nil)
				return
			}
			
			self?.successMessage.value = NotifiableSuccess(title: "Profile saved".localized(), text: nil)
			
		})
	}
	
	//MARK: -
	
	func validate() -> [String]? {
		if let eml = email.value, !eml.isValidEmail()/* && eml != "" */{
			return ["EMAIL IS NOT VALID".localized()]
		}
		return nil
	}
	
}
