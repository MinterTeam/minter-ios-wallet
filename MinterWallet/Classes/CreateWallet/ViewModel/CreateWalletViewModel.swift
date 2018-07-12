//
//  CreateWalletCreateWalletViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 03/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift
import MinterCore
import MinterMy



class CreateWalletViewModel: AccountantBaseViewModel {
	
	enum registerFormError : Error {
		case usernameTooShort
		case incorrectUsername
		case usernameTaken
		case passwordTooShort
		case passwordsAreNotEqual
		case emailIsInvalid
	}
	
	enum cellIdentifierPrefix : String {
		case username = "TextFieldTableViewCell_Username"
		case password = "TextFieldTableViewCell_Password"
		case confirmPassword = "TextFieldTableViewCell_ConfirmPassword"
		case email = "TextFieldTableViewCell_Email"
		case mobile = "TextFieldTableViewCell_Mobile"
	}
	
	//MARK: -
	
	var username = Variable<String?>(nil)
	private var isUsernameTaken = true
	var password = Variable<String?>(nil)
	var confirmPassword = Variable<String?>(nil)
	var email = Variable<String?>(nil)
	var mobile = Variable<String?>(nil)

	
	var shouldReloadTable = Variable(false)
	
	var isLoading = Variable(false)
	
	//MARK: -
	
	private let authManager = AuthManager.default
	
	private let disposeBag = DisposeBag()
	
	private var sections = Variable([BaseTableSectionItem]())
	
	var notifiableError = Variable<NotifiableError?>(nil)

	//MARK: -

	var title: String {
		get {
			return "Create Wallet".localized()
		}
	}

	override init() {
		super.init()
		
		createSections()
	}
	
	var sectionsObservable: Observable<[BaseTableSectionItem]> {
		return self.sections.asObservable()
	}
	
	private func createSections() {
		
		var sctns = [BaseTableSectionItem]()
		
		let username = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: cellIdentifierPrefix.username.rawValue)
		username.title = "CHOOSE @USERNAME".localized()
		username.prefix = "@"
		username.value = self.username.value
		username.state = .default
		username.keyboardType = .emailAddress
		
//		var passwordId = cellIdentifierPrefix.password.rawValue + "_"
//		passwordId += (self.password.value ?? "") + "_" + (self.confirmPassword.value ?? "")
		
		let password = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: cellIdentifierPrefix.password.rawValue)
		password.title = "CHOOSE PASSWORD".localized()
		password.isSecure = true
		password.value = self.password.value
		password.prefix = nil
		password.state = .default
		
		let confirmPassword = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: cellIdentifierPrefix.confirmPassword.rawValue)
		confirmPassword.title = "CONFIRM PASSWORD".localized()
		confirmPassword.isSecure = true
		confirmPassword.value = self.confirmPassword.value
		confirmPassword.state = .default
		
		let email = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: cellIdentifierPrefix.email.rawValue)
		email.title = "EMAIL (OPTIONAL *)".localized()
		email.value = self.email.value
		email.state = .default
		email.keyboardType = .emailAddress
		
//		let mobile = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: cellIdentifierPrefix.mobile.rawValue)
//		mobile.title = "MOBILE NUMBER (OPTIONAL *)".localized()
//		mobile.value = self.mobile.value
//		mobile.keyboardType = .phonePad
		
		var section = BaseTableSectionItem(header: "")
		section.identifier = "CreateWalletSection"
		section.items = [username, password, confirmPassword, email]
		sctns.append(section)
		
		sections.value = sctns
	}
	
	//MARK: -

	func rowsCount(for section: Int) -> Int {
		return sections.value[safe: section]?.items.count ?? 0
	}
	
	func cellItem(section: Int, row: Int) -> BaseCellItem? {
		return sections.value[safe: section]?.items[safe: row]
	}
	
	func validate(item: BaseCellItem, value: String, forceError: Bool = false, completion: ((Bool?, registerFormError?) -> ())?) {

		if item.identifier.hasPrefix(cellIdentifierPrefix.username.rawValue) {
			self.username.value = value
			
			if value.count < 5 {
				guard value != "" else {
					completion?(nil, nil)
					return
				}
				
//				if !forceError {
//					completion?(nil, nil)
//				}
//				else {
//						completion?(false, registerFormError.usernameTooShort)
//				}
				completion?(false, registerFormError.usernameTooShort)
				return
			}
			
			isUsernameTaken = true
			
			if !isUsernameValid(username: value) {
				completion?(false, registerFormError.usernameTaken)
				return
			}
			
			self.checkUsername().subscribe(
				onError: { [weak self] (err) in
					self?.isUsernameTaken = true
					completion?(false, registerFormError.usernameTaken)
				}, onCompleted: { [weak self] in
					self?.isUsernameTaken = false
					completion?(true, nil)
			}).disposed(by: disposeBag)
		}
		else if item.identifier.hasPrefix(cellIdentifierPrefix.password.rawValue) {
			self.password.value = value
			
			guard value != "" else {
				completion?(nil, nil)
				return
			}
			
			if !isPasswordValid(password: value) {
				completion?(false, registerFormError.passwordTooShort)
			}
			else {
				completion?(true, nil)
			}
		}
		else if item.identifier.hasPrefix(cellIdentifierPrefix.confirmPassword.rawValue) {
			self.confirmPassword.value = value
			
			guard value != "" else {
				completion?(nil, nil)
				return
			}
			
			if !isPasswordValid(password: value) || self.confirmPassword.value != self.password.value {
				completion?(false, registerFormError.passwordsAreNotEqual)
			}
			else {
				completion?(true, nil)
			}
		}
		else if item.identifier.hasPrefix(cellIdentifierPrefix.email.rawValue) {
			self.email.value = value
			
			guard value != "" else {
				completion?(nil, nil)
				return
			}
			
			if value.isValidEmail() {
				completion?(true, nil)
			}
			else {
				completion?(false, registerFormError.emailIsInvalid)
			}
		}
		else if item.identifier.hasPrefix(cellIdentifierPrefix.mobile.rawValue) {
			self.mobile.value = value
			
			guard value != "" else {
				completion?(nil, nil)
				return
			}
			
		}
	}
	
	func errorMessage(for error: registerFormError) -> String? {
		switch error {
			
		case .usernameTooShort:
			return "USERNAME IS TOO SHORT".localized()
			
		case .emailIsInvalid:
			return "EMAIL IS NOT VALID".localized()
			
		case .incorrectUsername:
			return "USERNAME IS INCORRECT".localized()
			
		case .passwordsAreNotEqual:
			return "PASSWORDS ARE NOT EQUAL".localized()
			
		case .passwordTooShort:
			return "PASSWORD IS TOO SHORT".localized()
			
		case .usernameTaken:
			return "USERNAME IS TAKEN".localized()
		}
	}
	
	private func checkUsername() -> Observable<Bool> {
		//formErrors.value[identifier] = "Some important error"
		return Observable.create { [weak self] observer in
			if let username = self?.username.value {

				self?.authManager.isTaken(username: username) { (isTaken, error) in
					guard nil == error else {
						observer.onError(error!)
						return
					}
					
					if isTaken == true {
						observer.onError(registerFormError.usernameTaken)
					}
					else {
						observer.onCompleted()
					}
				}
			}
			else {
				observer.onError(registerFormError.incorrectUsername)
			}
			return Disposables.create()
		}
	}
	
	//MARK: -
	
	func register() {
		
		isLoading.value = true
		var startedProcessing = true
		
		
		defer {
			if startedProcessing {
				isLoading.value = false
			}
		}
		
		guard let username = self.username.value, let password = self.password.value, let confirmPassword = self.confirmPassword.value, !isUsernameTaken else {
//			self.notifiableError.value = NotifiableError(title: "Form is not valid".localized(), text: nil)
			return
		}
		
		let email = self.email.value
		let mobile = self.mobile.value

		guard isUsernameValid(username: username) && isPasswordValid(password: password) && password == confirmPassword && isEmailValid(email: email) && isMobileValid(mobile: mobile) else {
//			self.notifiableError.value = NotifiableError(title: "Form is not valid".localized(), text: nil)
			return
		}
		
		//Generate mnemonic and encrypt with password
		guard let mnemonic = String.generateMnemonicString() else {
			self.notifiableError.value = NotifiableError(title: "Can't get mnemonic to encrypt".localized(), text: nil)
			return
		}
		
		accountManager.save(password: password)
		
		guard
			let seed = accountManager.seed(mnemonic: mnemonic, passphrase: ""),
			let account = accountManager.account(id: -1, seed: seed, encryptedBy: .bipWallet) else {
				return
		}
		
		guard let passwordToEncrypt = accountManager.password(), let encryptedMnemonic = try? accountManager.encryptedMnemonic(mnemonic: mnemonic, password: passwordToEncrypt), let encrypted = encryptedMnemonic?.toHexString() else {
			self.notifiableError.value = NotifiableError(title: "Can't encrypt mnemonic".localized(), text: nil)
			//Error
			return
		}
		
		//sending double sha256
		
		startedProcessing = false
		
		authManager.register(username: username, password: accountManager.accountPassword(password), email: email ?? "", phone: mobile ?? "", account: account, encrypted: encrypted) { [weak self] (isRegistered, error) in

			guard nil == error else {
				self?.isLoading.value = false
				
				switch error! {
				case .custom(let code, let message):
					if let errorMessage = message {
						self?.notifiableError.value = NotifiableError(title: message, text: nil)
					}
					else {
						self?.notifiableError.value = NotifiableError(title: "Something went wrong".localized(), text: nil)
					}
					break
				}
				return
			}

			//save here
			guard let account = self?.saveAccount(id: account.id, mnemonic: mnemonic, isLocal: false) else {
				self?.notifiableError.value = NotifiableError(title: "Something went wrong".localized(), text: nil)
				return
			}
			
			self?.login(username: username, password: self!.accountManager.accountPassword(password))

		}
	}
	
	func login(username: String, password: String) {
		
		authManager.login(username: username, password: password) { [weak self] (accessToken, refreshToken, user, error) in
			self?.isLoading.value = false
			
			guard nil == error else {
				self?.notifiableError.value = NotifiableError(title: "Unable to log in".localized(), text: nil)
				return
			}
			
			SessionHelper.set(accessToken: accessToken, refreshToken: refreshToken, user: user)
		}
	}
	
	//MARK: - Form Validation
	
	//Move to helper?
	private func isUsernameValid(username: String) -> Bool {
		let usernameTest = NSPredicate(format:"SELF MATCHES %@", "^[a-zA-Z0-9_]{5,32}")
		return usernameTest.evaluate(with: username)
	}
	
	private func isPasswordValid(password: String) -> Bool {
		return password.count >= 6
	}
	
	private func isEmailValid(email: String?) -> Bool {
		
		if email == "" || email == nil {
			return true
		}
		
		return email!.isValidEmail()
	}
	
	private func isMobileValid(mobile: String?) -> Bool {
		if nil != mobile {
			return String.isPhoneValid(mobile!)
		}
		return true
	}

}
