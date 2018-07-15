//
//  AddressAddressViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 20/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift
import RxDataSources
import MinterCore
import MinterMy


class AddressViewModel: BaseViewModel {

	var title: String {
		get {
			return "My Addresses".localized()
		}
	}
	
	private var disposableBag = DisposeBag()
	private let accountManager = AccountManager()
	
	//MARK: -
	
	private var sections = Variable([BaseTableSectionItem]())
	
	let accounts = Session.shared.accounts.value.sorted { (acc1, acc2) -> Bool in
		return acc1.isMain && !acc2.isMain
	}

	//MARK: -
	
	override init() {
		super.init()
		
		Session.shared.accounts.asObservable().subscribe(onNext: { [weak self] (accounts) in
			self?.createSections()
		}).disposed(by: disposableBag)
		
		createSections()
	}
	
	//MARK: -
	
	var accountObservable: Observable<[BaseTableSectionItem]> {
		return self.sections.asObservable()
	}
	
	//MARK: -
	
	private func createSections() {
		
		let allBalances = Session.shared.allBalances.value
		
		var addressNum = 0
		let sctns = accounts.map { (account) -> BaseTableSectionItem in
			addressNum += 1
			
			let sectionId = account.address
			
			let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell_1\(sectionId)")
			let separator1 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell_2\(sectionId)")
			let separator2 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell_3\(sectionId)")
			let separator3 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell_4\(sectionId)")
			
			let address = AddressTableViewCellItem(reuseIdentifier: "AddressTableViewCell", identifier: "AddressTableViewCell_\(sectionId)")
			address.address = account.address
			address.buttonTitle = "Copy".localized()
			
			let coins = Session.shared.baseCoinBalances.value
			
			let balance = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell", identifier: "DisclosureTableViewCell_Balance_1\(sectionId)")
			balance.title = "Balance".localized()
			balance.value = String(coins[account.address] ?? 0.0)
			balance.placeholder = ""
			
			let secured = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell", identifier: "DisclosureTableViewCell_Secured_2\(sectionId)")
			secured.title = "Secured by".localized()
			
			switch account.encryptedBy {
			case .bipWallet:
				secured.value = "BIP Wallet".localized()
				break
				
			case .me:
				secured.value = "Me".localized()
				break
			}
			secured.placeholder = "Change".localized()
			secured.showIndicator = false
			
			let setMain = SwitchTableViewCellItem(reuseIdentifier: "SettingsSwitchTableViewCell", identifier: "SettingsSwitchTableViewCell_\(sectionId)")
			setMain.isOn.value = account.isMain
			setMain.title = "Set as main".localized()
			
			var headerTitle = "ADDRESS #\(addressNum)".localized()
			if account.isMain == true {
				headerTitle = "MAIN ADDRESS".localized()
			}
			var section = BaseTableSectionItem(header: headerTitle)
			section.identifier = sectionId
			
			section.items = [address, separator, balance, separator1, secured, separator2]
			if accounts.count > 1 {
				section.items.append(setMain)
				section.items.append(separator3)
			}
			
			return section
		}
		
		sections.value = sctns
	}
	
	//MARK: -
	
	func setMainAccount(isMain: Bool, cellItem: BaseCellItem) {
		
		guard isMain == true && cellItem.identifier.hasPrefix("SettingsSwitchTableViewCell_") else {
			return
		}
		
		let accountAddress = cellItem.identifier.replacingOccurrences(of: "SettingsSwitchTableViewCell_", with: "")
		
//		sections.value.forEach { (sec) in
//			sec.items.forEach({ (item) in
//				if let item = item as? SwitchTableViewCellItem, cellItem.identifier != item.identifier {
//					item.isOn.value = false
//				}
//			})
//		}
		
		Session.shared.accounts.value = Session.shared.accounts.value.map({ (account) -> Account in
			var acc = account
			acc.isMain = false
			
			if account.address == accountAddress {
				accountManager.setMain(isMain: true, account: &acc)
			}
			
			return acc
		})
		
		return
		
		
		//Set all session main accounts to false
		for var account in Session.shared.accounts.value {
			account.isMain = false
		}
		//Find out which is the main now
		let idx = Session.shared.accounts.value.index { (acc) -> Bool in
			return acc.address == accountAddress
		}
		
		//Set the main and make it first
		var mainAccount = Session.shared.accounts.value[idx!]
		mainAccount.isMain = true
		
//		Session.shared.accounts.value =
		
	}
	
	//MARK: -
	
	func account(for index: Int) -> Account? {
		return accounts[safe: index]
	}
	
	//MARK: - TableView
	
	func section(index: Int) -> BaseTableSectionItem? {
		return sections.value[safe: index]
	}
	
	func sectionsCount() -> Int {
		return sections.value.count
	}
	
	func rowsCount(for section: Int) -> Int {
		return sections.value[safe: section]?.items.count ?? 0
	}
	
	func cellItem(section: Int, row: Int) -> BaseCellItem? {
		return sections.value[safe: section]?.items[safe: row]
	}
	
}
