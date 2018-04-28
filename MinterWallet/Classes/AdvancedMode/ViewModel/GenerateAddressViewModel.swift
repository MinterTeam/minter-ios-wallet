//
//  GenerateAddressViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 27/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation

class GenerateAddressViewModel : BaseViewModel {
	
	//MARK: -
	
	var title: String {
		get {
			return "Generate Address".localized()
		}
	}
	
	//MARK: -
	
	private var sections: [BaseTableSectionItem] = []
	
	override init() {
		super.init()
		
		createSections()
	}
	
	private func createSections() {
		
		let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell")
		
		let text = GenerateAddressLabelTableViewCellItem(reuseIdentifier: "GenerateAddressLabelTableViewCell", identifier: "GenerateAddressLabelTableViewCell")
		text.text = "Save this seed phrase in case you plan to use this address in the future.".localized()
		
		let seed = GenerateAddressSeedTableViewCellItem(reuseIdentifier: "GenerateAddressSeedTableViewCell", identifier: "GenerateAddressSeedTableViewCell")
		seed.phrase = "sun table orange mother"
		
		let saved = SwitchTableViewCellItem(reuseIdentifier: "SettingsSwitchTableViewCell", identifier: "SettingsSwitchTableViewCell")
		saved.title = "I've saved the phrase!".localized()
		
		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell", identifier: "ButtonTableViewCell")
		button.title = "LAUNCH THE WALLET".localized()
		button.buttonPattern = "purple"
		
		let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell", identifier: "BlankTableViewCell")
		
		let section = BaseTableSectionItem()
		section.title = "".localized()
		section.cells = [text, separator, seed, separator, saved, separator, blank, button]
		
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
