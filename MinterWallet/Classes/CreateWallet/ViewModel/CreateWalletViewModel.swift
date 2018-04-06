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
		
		let username = TextFieldTableViewCellItem()
		username.title = "CHOOSE @USERNAME".localized()
		username.prefix = "@"
		
		let password = TextFieldTableViewCellItem()
		password.title = "CHOOSE PASSWORD".localized()
		password.isSecure = true

		let confirmPassword = TextFieldTableViewCellItem()
		confirmPassword.title = "CONFIRM PASSWORD".localized()
		confirmPassword.isSecure = true
		
		let email = TextFieldTableViewCellItem()
		email.title = "EMAIL (OPTIONAL *)".localized()

		let mobileNumber = TextFieldTableViewCellItem()
		mobileNumber.title = "MOBILE NUMBER (OPTIONAL *)".localized()
		
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
