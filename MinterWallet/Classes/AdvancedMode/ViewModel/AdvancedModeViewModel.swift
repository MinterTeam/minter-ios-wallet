//
//  AdvancedModeAdvancedModeViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 26/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift



class AdvancedModeViewModel: BaseViewModel {
	
	enum ValidationError : String {
		case wrongMnemonic
	}

	//MARK: -
	
	var title: String {
		get {
			return "AdvancedMode".localized()
		}
	}

	override init() {
		super.init()
	}
	
	//MARK: -
	
	private let databaseStorage = RealmDatabaseStorage.shared
	
	//MARK: -
	
	private let accountManager = AccountManager()
	
	func saveAccount(mnemonic: String) {
		
		guard
			let seed = accountManager.seed(mnemonic: mnemonic, passphrase: ""),
			let account = accountManager.account(seed: seed, encryptedBy: .me) else {
				return
		}
		
		let dbModel = AccountDataBaseModel()
		dbModel.address = account.address
		dbModel.encryptedBy = account.encryptedBy.rawValue
		
		databaseStorage.add(object: dbModel)
	}
	
	func validationText(for error: ValidationError) -> String {
		switch error {
		case .wrongMnemonic:
			
			return "INCOREECT SEED PHRASE".localized()
			
		default:
			return ""
		}
	}
	
	
}
