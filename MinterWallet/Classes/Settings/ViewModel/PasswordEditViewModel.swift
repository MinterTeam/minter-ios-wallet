//
//  PasswordEditViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 27/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import RxSwift
import MinterMy


enum PasswordChangeError : Error {
	case canNotGetLocalAccounts
	case canNotGetEcryptionKey
	case canNotSaveMnemonic
}

class PasswordEditViewModel: BaseViewModel {
	
	//MARK: -
	
	override init() {
		super.init()
		
		createSection()
	}
	
	//MARK: -
	
	var title: String {
		get {
			return "Password".localized()
		}
	}
	
	private var isLoading = Variable(false)
	
	var password = Variable<String?>(nil)
	var confirmPassword = Variable<String?>(nil)
	
	private var isButtonEnabledObserver: Observable<Bool> {
		return Observable.combineLatest(password.asObservable(), confirmPassword.asObservable()).map({ (val) -> Bool in
			return val.0 != nil && (val.0 ?? "") == (val.1 ?? "") && self.isPasswordValid(password: (val.0 ?? ""))
		})
	}
	
	//MARK: - TableView
	
	var sections: [BaseTableSectionItem] = []
	
	func createSection() {
		
		var section = BaseTableSectionItem(header: "")
		
		let password = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: "TextFieldTableViewCell_Password")
		password.title = "CHOOSE PASSWORD".localized()
		password.isSecure = true
		
		let confirmPassword = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: "TextFieldTableViewCell_PasswordConfirm")
		confirmPassword.title = "CONFIRM PASSWORD".localized()
		confirmPassword.isSecure = true
		
		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell", identifier: "ButtonTableViewCell")
		button.title = "Save"
		button.buttonPattern = "purple"
		button.isLoadingObserver = self.isLoading.asObservable()
		button.isButtonEnabled = false
		button.isButtonEnabledObservable = self.isButtonEnabledObserver
		
		section.items = [password, confirmPassword, button]
		
		sections.append(section)
	}
	
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
	
	//MARK: -
	
	private func isPasswordValid(password: String) -> Bool {
		return password.count >= 6
	}
	
	func validate(item: BaseCellItem) -> [String]? {
		
		var errors: [String]? = []
		if item.identifier == "TextFieldTableViewCell_Password" {
			if !isPasswordValid(password: self.password.value ?? "") {
				if self.password.value == "" {
					
				}
				else {
					errors?.append("PASSWORD IS TOO SHORT".localized())
				}
			}
		}
		else if item.identifier == "TextFieldTableViewCell_PasswordConfirm" {
			if (self.password.value ?? "") != (self.confirmPassword.value ?? "") {
				if self.confirmPassword.value == "" {
					
				}
				else {
					errors?.append("PASSWORDS ARE NOT EQUAL".localized())
				}
			}
		}
		return errors
	}
	
	func changePassword() {
		
		self.isLoading.value = true
		
		DispatchQueue.global(qos: .default).async {
			DispatchQueue.main.async {
				let mnemonics = try? self.step1()
				
				let newRawPwd = self.newPassword()
				try? self.step2(mnemonics: mnemonics ?? [], rawPassword: newRawPwd!)
				
				
			}
		}

	}
	
	private func newPassword() -> String? {
		
		guard let pwd = self.password.value, let cpwd = self.confirmPassword.value, pwd == cpwd && isPasswordValid(password: pwd) else {
			return nil
		}
		
		return pwd
	}
	
	private let accountManager = AccountManager(secureStorage: SecureStorage(namespace: "ReserveSecureStorage"))
	private let oldAccountManager = AccountManager()
	
	//get decrypted mnemonics
	private func step1() throws -> [String]  {
		
		guard let accounts = oldAccountManager.loadLocalAccounts() else {
			throw PasswordChangeError.canNotGetLocalAccounts
			return []
		}

		var rawPassword: String?
		
		let mnemonics = accounts.map { (account) -> String? in
			return oldAccountManager.mnemonic(for: account.address)
		}.filter { (mnemonic) -> Bool in
			return mnemonic != nil
		} as! [String]
		
		return mnemonics
	}
	
	//Get new encrypt key
	private func step2(mnemonics: [String], rawPassword: String) throws {
		
		accountManager.save(password: rawPassword)
		
		guard let encKey = accountManager.password() else {
			throw PasswordChangeError.canNotGetEcryptionKey
		}
		
		try? mnemonics.forEach { (mnemonic) in
			do {
				try self.accountManager.save(mnemonic: mnemonic, password: encKey)
			}
			catch {
				throw PasswordChangeError.canNotSaveMnemonic
			}
		}
	}
	
	//Send to server
	private func step3() {
		
		guard let pwd = newPassword() else {
			return
		}
		
		let newPwd = accountManager.accountPassword(pwd)
		
		AuthManager.default.changePassword(newPassword: <#T##String#>, encryptedMnemonics: <#T##String#>, completion: <#T##((Bool?, AuthManager.AuthManagerLoginError?) -> ())?##((Bool?, AuthManager.AuthManagerLoginError?) -> ())?##(Bool?, AuthManager.AuthManagerLoginError?) -> ()#>)
	}


}
