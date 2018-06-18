//
//  SettingsSettingsViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 19/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift

class SettingsViewModel: BaseViewModel {
	
	//MARK: -

	var title: String {
		get {
			return "Settings".localized()
		}
	}
	
	private var sections: [BaseTableSectionItem] = []
	
	var showLoginScreen = Variable(false)
	
	var shouldReloadTable = Variable(false)
	
	private var disposeBag = DisposeBag()
	
	//MARK: -

	override init() {
		super.init()
		
		Session.shared.isLoggedIn.asObservable().distinctUntilChanged().subscribe(onNext: { [weak self] (val) in
			self?.createSections()
			self?.shouldReloadTable.value = true
		}).disposed(by: disposeBag)
		
		createSections()
	}
	
	var rightButtonTitle : String {
		return "Log Out".localized()
	}
	
	//MARK: - Sections
	
	func createSections() {
		
		var sctns = [BaseTableSectionItem]()
		
		let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell")
		
		if Session.shared.isLoggedIn.value {
			
			let avatar = SettingsAvatarTableViewCellItem(reuseIdentifier: "SettingsAvatarTableViewCell", identifier: "SettingsAvatarTableViewCell")
			let username = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell", identifier: "DisclosureTableViewCell_Username")
			username.title = "Username".localized()
			username.value = "@AlexeySidorov"
			username.placeholder = "Change"

			let mobile = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell", identifier: "DisclosureTableViewCell_Mobile")
			mobile.title = "Mobile".localized()
			mobile.value = "+7 999 600 0000"
			mobile.placeholder = "Change"

			let email = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell", identifier: "DisclosureTableViewCell_Email")
			email.title = "Email".localized()
			email.value = nil
			email.placeholder = "Add"
			
			let password = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell", identifier: "DisclosureTableViewCell_Password")
			password.title = "Password".localized()
			password.value = nil
			password.placeholder = "Change"
			
			var items: [BaseCellItem] = []
			
			var section = BaseTableSectionItem(header: "")

			items = [avatar, separator, username, separator, mobile, separator, email, separator, password, separator]
			section.items = items
			sctns.append(section)
			
			sections = sctns
		}
		
		let language = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell", identifier: "DisclosureTableViewCell_Language")
		language.title = "Language".localized()
		language.value = "English"
		language.placeholder = "Change"

		let addresses = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell", identifier: "DisclosureTableViewCell_Addresses")
		addresses.title = "My Addresses".localized()
		addresses.value = nil
		addresses.placeholder = "Manage"
		
		var section1 = BaseTableSectionItem(header: " ")
		section1.items = [language, separator, addresses]
		sections.append(section1)
		
	}
	
	//MARK: - Rows
	
	func sectionsCount() -> Int {
		return sections.count
	}
	
	func rowsCount(for section: Int) -> Int {
		return sections[safe: section]?.items.count ?? 0
	}
	
	func cellItem(section: Int, row: Int) -> BaseCellItem? {
		return sections[safe: section]?.items[safe: row]
	}
	
	func section(index: Int) -> BaseTableSectionItem? {
		return sections[safe: index]
	}
	
	//MARK: -
	
	func rightButtonTapped() {
		Session.shared.logout()
	}

}
