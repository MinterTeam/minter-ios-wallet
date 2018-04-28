//
//  CreateWalletCreateWalletViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 03/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift


class FormSectionItem : BaseTableSectionItem {
	
}


class CreateWalletViewModel: BaseViewModel {
	
	//MARK: -
	
	var shouldReloadTable = Variable(false)
	
	//MARK: -
	
	private var sections: [FormSectionItem] = []

	//MARK: -

	var title: String {
		get {
			return "Create Wallet".localized()
		}
	}

	override init() {
		super.init()
		
		let username = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: "TextFieldTableViewCell_Username")
		username.title = "CHOOSE @USERNAME".localized()
		username.prefix = "@"
		username.value = "ariil"
		username.state = .valid
		
		let password = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: "TextFieldTableViewCell_Password")
		password.title = "CHOOSE PASSWORD".localized()
		password.isSecure = true

		let confirmPassword = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: "TextFieldTableViewCell_PasswordConfirm")
		confirmPassword.title = "CONFIRM PASSWORD".localized()
		confirmPassword.isSecure = true
		
		let email = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: "TextFieldTableViewCell_Email")
		email.title = "EMAIL (OPTIONAL *)".localized()

		let mobileNumber = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: "TextFieldTableViewCell_Mobile")
		mobileNumber.title = "MOBILE NUMBER (OPTIONAL *)".localized()
		mobileNumber.state = .invalid
		
		let section = FormSectionItem()
		section.cells = [username, password, confirmPassword, email, mobileNumber]
		sections.append(section)
	}
	
	//MARK: -

	func rowsCount(for section: Int) -> Int {
		return sections[safe: section]?.cells.count ?? 0
	}
	
	func cellItem(section: Int, row: Int) -> BaseCellItem? {
		return sections[safe: section]?.cells[safe: row]
	}

}
