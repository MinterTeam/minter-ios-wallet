//
//  AdvancedModeAdvancedModeViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 26/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift
import GoldenKeystore

class AdvancedModeViewModel: AccountantBaseViewModel {
	
	enum ValidationError : String {
		case wrongMnemonic
	}

	//MARK: -
	
	var title: String {
		get {
			return "Advanced Mode".localized()
		}
	}

	override init() {
		super.init()
	}
	
	//MARK: -
	
	private let databaseStorage = RealmDatabaseStorage.shared
	
	//MARK: -
	
//	private let accountManager = AccountManager()
	
	func saveAccount(mnemonic: String) {

		guard
			let seed = accountManager.seed(mnemonic: mnemonic, passphrase: ""),
			let account = accountManager.account(id: -1, seed: seed, encryptedBy: .me) else {
				return
		}

		let dbModel = AccountDataBaseModel()
		dbModel.id = account.id
		dbModel.address = account.address
		dbModel.encryptedBy = account.encryptedBy.rawValue

		databaseStorage.add(object: dbModel)
	}
	
	func isCorrect(mnemonic: String) -> ValidationError? {
		let array = mnemonic.split(separator: " ")
		guard array.count == 12 else {
			return .wrongMnemonic
		}
		if GoldenKeystore.mnemonicIsValid(mnemonic) {
			return nil
		}
		return .wrongMnemonic
	}
	
	func validationText(for error: ValidationError) -> String {
		switch error {
		case .wrongMnemonic:
			return "INCORRECT SEED PHRASE".localized()
			
		default:
			return ""
		}
	}

}
