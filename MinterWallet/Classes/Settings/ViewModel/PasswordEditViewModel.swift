//
//  PasswordEditViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 27/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore
import MinterMy
import NotificationBannerSwift

enum PasswordChangeError : Error {
	case canNotGetLocalAccounts
	case canNotGetEncryptionKey
	case canNotGetMnemonic
	case canNotEncryptMnemonic
	case canNotSaveMnemonic
	case canNotGetAccountPassword
}

class PasswordEditViewModel: BaseViewModel {

	// MARK: -

	override init() {
		super.init()
		
		createSection()
	}

	// MARK: -

	var title: String {
		get {
			return "Change Password".localized()
		}
	}

	var errorNotification = Variable<NotifiableError?>(nil)

	var successMessage = Variable<NotifiableSuccess?>(nil)
	
	private var isLoading = Variable(false)

	var password = Variable<String?>(nil)
	var confirmPassword = Variable<String?>(nil)

	private var isButtonEnabledObserver: Observable<Bool> {
		return Observable.combineLatest(password.asObservable(),
																		confirmPassword.asObservable()).map({ (val) -> Bool in
			return val.0 != nil
				&& (val.0 ?? "") == (val.1 ?? "")
				&& self.isPasswordValid(password: (val.0 ?? ""))
		})
	}

	// MARK: - TableView

	var sections: [BaseTableSectionItem] = []

	func createSection() {

		var section = BaseTableSectionItem(header: "")
		
		let password = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell",
																							identifier: "TextFieldTableViewCell_Password")
		password.title = "NEW PASSWORD".localized()
		password.isSecure = true
		
		let confirmPassword = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell",
																										 identifier: "TextFieldTableViewCell_PasswordConfirm")
		confirmPassword.title = "REPEAT NEW PASSWORD".localized()
		confirmPassword.isSecure = true
		
		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
																				 identifier: "ButtonTableViewCell")
		button.title = "SAVE".localized()
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

	// MARK: -
	
	private func isPasswordValid(password: String) -> Bool {
		return password.count >= 6
	}

	func validate(item: BaseCellItem) -> [String]? {

		var errors: [String]? = []
		if item.identifier == "TextFieldTableViewCell_Password" {
			if !isPasswordValid(password: self.password.value ?? "") {
				if self.password.value == "" {
					
				} else {
					errors?.append("PASSWORD IS TOO SHORT".localized())
				}
			}
		} else if item.identifier == "TextFieldTableViewCell_PasswordConfirm" {
			if (self.password.value ?? "") != (self.confirmPassword.value ?? "") {
				if self.confirmPassword.value == "" {
					
				} else {
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
				do {
					try self.start()
				} catch {
					self.errorNotification.value = NotifiableError(title: "Password can't be changed. Please try again later".localized(),
																												 text: nil)
					self.isLoading.value = false
				}
			}
		}
	}

	private func newPassword() -> String? {
		guard let pwd = self.password.value,
			let cpwd = self.confirmPassword.value,
			pwd == cpwd && isPasswordValid(password: pwd) else {
				return nil
		}

		return pwd
	}

	private let rescueStorage = SecureStorage(namespace: "ReserveSecureStorage")
	private var accountManager: AccountManager?
	private let oldAccountManager = AccountManager()
	private var authManager: AuthManager?

	//Send to server
	private func start() throws {

		accountManager = AccountManager(secureStorage: rescueStorage)

		guard let pwd = newPassword() else {
			return
		}

		//Loading local accounts
		guard let accounts = oldAccountManager.loadLocalAccounts() else {
			throw PasswordChangeError.canNotGetLocalAccounts
		}

		//getting encryption key to decrypt
		guard let oldEncryptionKey = self.oldAccountManager.password() else {
			throw PasswordChangeError.canNotGetEncryptionKey
		}

		//saving new encryption key to the rescue storage
		accountManager?.save(password: pwd)

		guard let newEncryptionKey = self.accountManager?.password() else {
			throw PasswordChangeError.canNotGetEncryptionKey
		}

		let newPwd = pwd
		
		var mnemonics: [(id: Int, mnemonic: String)] = []
		
		var oldMnemonics: [(id: Int, mnemonic: String)] = []
		
		try? accounts.forEach { (account) in
			
			guard let mnemonic = oldAccountManager.mnemonic(for: account.address) else {
				throw PasswordChangeError.canNotGetMnemonic
			}
			
			if let oldEncryptedMnemonic = oldAccountManager.encryptedMnemonic(for: account.address) {
				oldMnemonics.append((id: account.id, mnemonic: oldEncryptedMnemonic.toHexString()))
			}
			
			guard let encryptedMnemonic = try self.accountManager?
				.encryptedMnemonic(mnemonic: mnemonic,
													 password: newEncryptionKey)?.toHexString() else {
				throw PasswordChangeError.canNotEncryptMnemonic
			}

			try self.accountManager?.save(mnemonic: mnemonic,
																		password: newEncryptionKey)

			mnemonics.append((id: account.id, mnemonic: encryptedMnemonic))

		}
		
		guard let client = APIClient.withAuthentication() else {
			return
		}
		
		self.authManager = AuthManager(httpClient: client)

		do {
			try self.authManager?.changePassword(oldEncryptedMnemoics: oldMnemonics,
																					 encryptionKey: oldEncryptionKey,
																					 newPassword: newPwd,
																					 completion: { (succeed, error) in

						self.isLoading.value = false
			
						if succeed == true {
			
							self.successMessage.value = NotifiableSuccess(title: "Password has been changed".localized(),
																														text: nil)
			
							do {
								try self.finish()
							}
							catch {
								//logout if can't finish PKs recovery
								Session.shared.logout()
							}
						}
						else {
							self.errorNotification.value = NotifiableError(title: "Password can't be changed. Please try again later".localized(),
																														 text: nil)
							try? self.cleanUp()
						}
			})
		} catch {
			self.errorNotification.value = NotifiableError(title: "Password can't be changed. Please try again later".localized(),
																										 text: nil)
		}
	}

	func finish() throws {
		guard let accounts = accountManager?.loadLocalAccounts() else {
			throw PasswordChangeError.canNotGetLocalAccounts
		}

		guard let newEncryptionKey = self.accountManager?.password() else {
			throw PasswordChangeError.canNotGetEncryptionKey
		}

		self.oldAccountManager.save(encryptionKey: newEncryptionKey)

		try? accounts.forEach { (account) in

			guard let mnemonic = accountManager?.mnemonic(for: account.address) else {
				throw PasswordChangeError.canNotGetMnemonic
			}

			try self.oldAccountManager.save(mnemonic: mnemonic, password: newEncryptionKey)

			try? self.cleanUp()
		}
	}

	func cleanUp() throws {
		accountManager?.deleteEncryptionKey()
	}

}
