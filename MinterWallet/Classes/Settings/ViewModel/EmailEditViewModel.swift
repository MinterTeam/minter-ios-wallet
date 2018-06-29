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
	
	//MARK: -
	
	private var isLoading = Variable(false)
	
	//MARK: -
	
	override init() {
		super.init()
		
		createSection()
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
		
		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell", identifier: "ButtonTableViewCell")
		button.buttonPattern = "purple"
		button.title = "SAVE".localized()
		button.isLoadingObserver = isLoading.asObservable()
		
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
	
}
