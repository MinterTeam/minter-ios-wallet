//
//  SendSendViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 13/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift


class SendViewModel: BaseViewModel {
	
	//MARK: -

	var title: String {
		get {
			return "Send".localized()
		}
	}
	
	//MARK: -
	
	var sections: [BaseTableSectionItem] = []
	
	//MARK: -

	override init() {
		super.init()
		
		createSections()
	}
	
	//MARK: - Sections
	
	func createSections() {
		let username = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: "TextFieldTableViewCell_Username")
		username.title = "CHOOSE @USERNAME".localized()
		username.prefix = "@"
		
		let coin = PickerTableViewCellItem(reuseIdentifier: "PickerTableViewCell", identifier: "PickerTableViewCell_Coin")
		coin.title = "COIN".localized()
		
		let amount = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: "TextFieldTableViewCell_Amount")
		amount.title = "AMOUNT".localized()
		
		let fee = TwoTitleTableViewCellItem(reuseIdentifier: "TwoTitleTableViewCell", identifier: "TwoTitleTableViewCell_TransactionFee")
		fee.title = "Transaction Fee".localized()
		fee.subtitle = "0.00000001 BIP"
		
		let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell")
		
		let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell", identifier: "BlankTableViewCell")
		
		let sendForFree = SwitchTableViewCellItem(reuseIdentifier: "SwitchTableViewCell", identifier: "SwitchTableViewCell")
		sendForFree.title = "Send for free!".localized()
		
		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell", identifier: "ButtonTableViewCell")
		button.title = "SEND!".localized()
		button.buttonPattern = "purple"
		
		
		var section = BaseTableSectionItem(header: "")
		section.items = [coin, username, amount, fee, separator, blank, sendForFree, separator, blank, button]
		sections.append(section)
	}

	//MARK: - Rows

	func rowsCount(for section: Int) -> Int {
		return sections[safe: section]?.items.count ?? 0
	}

	func cellItem(section: Int, row: Int) -> BaseCellItem? {
		return sections[safe: section]?.items[safe: row]
	}
	
	
}
