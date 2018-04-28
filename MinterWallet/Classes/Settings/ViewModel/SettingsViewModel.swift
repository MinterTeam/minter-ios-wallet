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
	
	//MARK: -

	override init() {
		super.init()
		
		createSections()
	}
	
	//MARK: - Sections
	
	func createSections() {
		
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
		
		let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell")
		
		let section = FormSectionItem()
		section.title = ""
		section.cells = [avatar, separator, username, separator, mobile, separator, email, separator, password, separator]
		sections.append(section)
		
		
		
		let language = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell", identifier: "DisclosureTableViewCell_Language")
		language.title = "Language".localized()
		language.value = "English"
		language.placeholder = "Change"

		let addresses = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell", identifier: "DisclosureTableViewCell_Addresses")
		addresses.title = "My Addresses".localized()
		addresses.value = nil
		addresses.placeholder = "Manage"
		
		
		let section1 = FormSectionItem()
		section1.title = " "
		section1.cells = [language, separator, addresses]
		sections.append(section1)
		
		
		
	}
	
	//MARK: - Rows
	
	func sectionsCount() -> Int {
		return sections.count
	}
	
	func rowsCount(for section: Int) -> Int {
		return sections[safe: section]?.cells.count ?? 0
	}
	
	func cellItem(section: Int, row: Int) -> BaseCellItem? {
		return sections[safe: section]?.cells[safe: row]
	}
	
	func section(index: Int) -> BaseTableSectionItem? {
		return sections[safe: index]
	}

}
