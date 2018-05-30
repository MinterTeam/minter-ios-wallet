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

class GenerateAddressViewModel : BaseViewModel {
	
	
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
	
	private let accountManager = AccountManager()
	
	func activate() {
		
		guard let mnemonic = mnemonic else {
			return
		}
		
		saveAccount(mnemonic: mnemonic)
	}
	
	func saveAccount(mnemonic: String) {

		guard
			let seed = accountManager.seed(mnemonic: mnemonic, passphrase: ""),
			let account = accountManager.account(seed: seed, encryptedBy: .me) else {
				return
		}
		
		var password = accountManager.password()
		if nil == password {
			accountManager.save(password: accountManager.generateRandomPassword(length: 32))
			password = accountManager.password()
		}
		
		guard nil != password else {
			assert(true)
			return
		}
		
		//save mnemonic
		accountManager.save(mnemonic: mnemonic, password: password!)
		
		let accounts = databaseStorage.objects(class: AccountDataBaseModel.self) as? [AccountDataBaseModel]
		let hasObjects = (accounts?.count ?? 0) > 0
		
		//No repeated accounts allowed
		guard (accounts ?? []).filter({ (acc) -> Bool in
			return acc.address == account.address
		}).count == 0 else {
			return
		}
		
		let dbModel = AccountDataBaseModel()
		dbModel.address = account.address
		dbModel.encryptedBy = account.encryptedBy.rawValue
		dbModel.isMain = !hasObjects
		databaseStorage.add(object: dbModel)
		
		SessionHelper.reloadAccounts()
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
