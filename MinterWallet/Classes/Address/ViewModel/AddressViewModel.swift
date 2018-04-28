//
//  AddressAddressViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 20/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift

class AddressViewModel: BaseViewModel {

	var title: String {
		get {
			return "Address".localized()
		}
	}
	
	//MARK: -
	
	private var sections: [BaseTableSectionItem] = []

	//MARK: -
	
	override init() {
		super.init()
		
		createSections()
	}
	
	private func createSections() {
		
		let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell")
		
		let address = AddressTableViewCellItem(reuseIdentifier: "AddressTableViewCell", identifier: "AddressTableViewCell")
		address.address = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		address.buttonTitle = "Copy".localized()
		
		let balance = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell", identifier: "DisclosureTableViewCell_Balance")
		balance.title = "Balance".localized()
		balance.value = "12.23213213"
		balance.placeholder = ""

		let secured = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell", identifier: "DisclosureTableViewCell_Secured")
		secured.title = "Secured by".localized()
		secured.value = "BIP Wallet".localized()
		secured.placeholder = "Change".localized()
		secured.showIndicator = false
		
		let setMain = SwitchTableViewCellItem(reuseIdentifier: "SettingsSwitchTableViewCell", identifier: "SettingsSwitchTableViewCell")
		setMain.title = "Set as main".localized()
		
		
		let section = BaseTableSectionItem()
		section.title = "MAIN ADDRESS".localized()
		section.cells = [address, separator, balance, separator, secured, separator, setMain, separator]
		
		sections.append(section)
	}
	
	//MARK: - TableView
	
	func section(index: Int) -> BaseTableSectionItem? {
		return sections[safe: index]
	}
	
	func sectionsCount() -> Int {
		return sections.count
	}
	
	func rowsCount(for section: Int) -> Int {
		return sections[safe: section]?.cells.count ?? 0
	}
	
	func cellItem(section: Int, row: Int) -> BaseCellItem? {
		return sections[safe: section]?.cells[safe: row]
	}
	
}
