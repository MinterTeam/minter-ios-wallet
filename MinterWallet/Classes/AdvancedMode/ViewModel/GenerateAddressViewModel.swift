//
//  GenerateAddressViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 27/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import MinterCore
import RxSwift

class GenerateAddressViewModel : AccountantBaseViewModel {
	
	
	let proceedAvailable = Variable(false)
	
	//MARK: -
	
	var title: String {
		get {
			return "Generate Address".localized()
		}
	}
	
	private var mnemonic: String?
	
	//MARK: -
	
	private let databaseStorage = RealmDatabaseStorage.shared
	
	//MARK: -
	
	private let isLoading = Variable(false)
	
	func activate() {
		
		isLoading.value = true
		
		guard let mnemonic = mnemonic else {
			return
		}
		
		self.saveAccount(id: -1, mnemonic: mnemonic)
		
		isLoading.value = false
	}
	
	func setMnemonicChecked(isChecked: Bool) {
		proceedAvailable.value = isChecked
	}
	
	//MARK: -
	
	private var sections: [BaseTableSectionItem] = []
	
	override init() {
		super.init()
		
		self.mnemonic = generateMnemonic()
		
		createSections()
	}
	
	private func createSections() {
		
		let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell")
		
		let text = GenerateAddressLabelTableViewCellItem(reuseIdentifier: "GenerateAddressLabelTableViewCell", identifier: "GenerateAddressLabelTableViewCell")
		text.text = "Save this seed phrase in case you plan to use this address in the future.".localized()
		
		let seedPhrase = self.mnemonic
		let seed = GenerateAddressSeedTableViewCellItem(reuseIdentifier: "GenerateAddressSeedTableViewCell", identifier: "GenerateAddressSeedTableViewCell")
		seed.phrase = seedPhrase
		
		let saved = SwitchTableViewCellItem(reuseIdentifier: "SettingsSwitchTableViewCell", identifier: "SettingsSwitchTableViewCell")
		saved.title = "I've saved the phrase!".localized()
		
		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell", identifier: "ButtonTableViewCell")
		button.title = "LAUNCH THE WALLET".localized()
		button.buttonPattern = "purple"
		button.isButtonEnabled = proceedAvailable.value
		button.isLoadingObserver = isLoading.asObservable()
		
		let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell", identifier: "BlankTableViewCell")
		
		var section = BaseTableSectionItem(header: "")
		section.items = [text, separator, seed, separator, saved, separator, blank, button]
		
		sections.append(section)
	}
	
	//MARK: -
	
	private func generateMnemonic() -> String? {
		return String.generateMnemonicString()
	}
	
	//MARK: - TableView
	
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
