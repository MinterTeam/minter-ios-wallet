//
//  LoginLoginViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift

class LoginViewModel: BaseViewModel {

	var title: String {
		get {
			return "Sign In".localized()
		}
	}

	private var sections: [BaseTableSectionItem] = []
	
	//MARK: -
	
	override init() {
		super.init()
		
		createSection()
	}
	
	func createSection() {
		let username = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: "TextFieldTableViewCell_Username")
		username.title = "CHOOSE @USERNAME".localized()
		username.prefix = "@"
		username.state = .valid
		
		let password = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: "TextFieldTableViewCell_Password")
		password.title = "CHOOSE PASSWORD".localized()
		password.isSecure = true
		
		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell", identifier: "ButtonTableViewCell")
		button.title = "CONTINUE".localized()
		button.buttonPattern = "purple"
		
		var section = BaseTableSectionItem(header: "")
		section.items = [username, password, button]
		sections.append(section)

	}
	
	//MARK: -
	
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

}
