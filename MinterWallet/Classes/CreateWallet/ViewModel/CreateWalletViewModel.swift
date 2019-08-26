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

class CreateWalletViewModel: AccountantBaseViewModel, ViewModelProtocol {
	
	//MARK: -
	
	struct Input {
		var createButtonDidTap: AnyObserver<Void>
	}
	
	struct Output {
		var isButtonEnabled: Observable<Bool>
		var isUsernameLoading: Observable<Bool>
	}
	
	var input: CreateWalletViewModel.Input!
	
	var output: CreateWalletViewModel.Output!

	//MARK: -
	
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
	private var isUsernameTaken = BehaviorSubject<Bool>(value: true)
	var password = Variable<String?>(nil)
	var confirmPassword = Variable<String?>(nil)
	var email = Variable<String?>(nil)
	var mobile = Variable<String?>(nil)
	
	let passwordStateObserver = ReplaySubject<TextFieldTableViewCell.State>.create(bufferSize: 1)
	let confirmPasswordObserver = ReplaySubject<TextFieldTableViewCell.State>.create(bufferSize: 1)
	
	var shouldReloadTable = Variable(false)
	
	var isLoading = Variable(false)
	
	//MARK: -
	
	private var createWalletDidTap = PublishSubject<Void>()
	
	//MARK: -
	
	private let authManager = AuthManager.default
	
	private var sections = Variable([BaseTableSectionItem]())
	
	var notifiableError = Variable<NotifiableError?>(nil)
	
	var isButtonEnabled: Observable<Bool> {
		return Observable.combineLatest(username.asObservable(), password.asObservable(), confirmPassword.asObservable(), isUsernameTaken.asObservable()).map({ (val) -> Bool in
			
			let (username, pwd, confirmPwd, isUsernameTkn) = val
			return UsernameValidator.isValid(username: username) && PasswordValidator.isValid(password: pwd) && pwd == confirmPwd && !isUsernameTkn
		})
	}
	
	private var isUsernameLoading = PublishSubject<Bool>()
	private var usernameState = ReplaySubject<TextFieldTableViewCell.State>.create(bufferSize: 1)
	

	//MARK: -

	var title: String {
		get {
			return "Create Wallet".localized()
		}
	}

	override init() {
		super.init()
		
		self.input = Input(createButtonDidTap: createWalletDidTap.asObserver())
		
		self.output = Output(
			isButtonEnabled: isButtonEnabled.asObservable(),
			isUsernameLoading: isUsernameLoading.asObservable()
		)
		
		createWalletDidTap.subscribe(onNext: { [weak self] _ in
			self?.register()
		}).disposed(by: disposeBag)
		
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
		username.isLoadingObservable = isUsernameLoading.asObservable()
		username.stateObservable = usernameState.asObservable()
		
		let password = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: cellIdentifierPrefix.password.rawValue)
		password.title = "CHOOSE PASSWORD".localized()
		password.isSecure = true
		password.value = self.password.value
		password.prefix = nil
		password.state = .default
		password.stateObservable = passwordStateObserver.asObservable()
		
		let confirmPassword = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: cellIdentifierPrefix.confirmPassword.rawValue)
		confirmPassword.title = "CONFIRM PASSWORD".localized()
		confirmPassword.isSecure = true
		confirmPassword.value = self.confirmPassword.value
		confirmPassword.state = .default
		confirmPassword.stateObservable = confirmPasswordObserver.asObservable()
		
		var section = BaseTableSectionItem(header: "")
		section.identifier = "CreateWalletSection"
		section.items = [username, password, confirmPassword]
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
			if value == self.username.value {
				return
			}
			
			self.username.value = value
			
			if !UsernameValidator.isValid(username: value) {
				guard value != "" else {
					completion?(nil, nil)
					return
				}

				completion?(false, registerFormError.usernameTooShort)
				usernameState.onNext(.invalid(error: errorMessage(for: .usernameTooShort)))
				return
			}
			
			isUsernameTaken.onNext(true)
			
			if !isUsernameValid(username: value) {
				completion?(false, registerFormError.incorrectUsername)
				usernameState.onNext(.invalid(error: errorMessage(for: .incorrectUsername)))
				return
			}
			
			self.checkUsername().subscribe(
				onError: { [weak self] (err) in
					self?.isUsernameTaken.onNext(true)
					completion?(false, registerFormError.usernameTaken)
					self?.usernameState.onNext(.invalid(error: self?.errorMessage(for: .usernameTaken)))
				}, onCompleted: { [weak self] in
					self?.isUsernameTaken.onNext(false)
					self?.usernameState.onNext(.valid)
					completion?(true, nil)
			}).disposed(by: disposeBag)
		}
		else if item.identifier.hasPrefix(cellIdentifierPrefix.password.rawValue) {
			self.password.value = value
			
			guard value != "" else {
				completion?(nil, nil)
				return
			}
			
			if isPasswordValid(password: value) {
				if self.confirmPassword.value == self.password.value {
					confirmPasswordObserver.onNext(.valid)
				}
				else {
					if self.confirmPassword.value != nil && self.confirmPassword.value != "" {
						confirmPasswordObserver.onNext(.invalid(error: errorMessage(for: .passwordsAreNotEqual)))
					}
					else {
						confirmPasswordObserver.onNext(.default)
					}
				}
				completion?(true, nil)
				return
			}
			else {
				completion?(false, registerFormError.passwordTooShort)
			}
		}
		else if item.identifier.hasPrefix(cellIdentifierPrefix.confirmPassword.rawValue) {
			self.confirmPassword.value = value
			
			guard value != "" else {
				completion?(nil, nil)
				return
			}
			
			if isPasswordValid(password: value) {
				if self.password.value == nil || self.password.value == "" {
					completion?(true, nil)
					return
				}
				else {
					if self.password.value != self.confirmPassword.value {
						completion?(false, registerFormError.passwordsAreNotEqual)
						return
					}
					else {
						passwordStateObserver.onNext(.valid)
						completion?(true, nil)
						return
					}
				}
			}
			else {
				completion?(false, registerFormError.passwordTooShort)
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
		return Observable.create { [weak self] observer in
			if let username = self?.username.value {
				
				self?.authManager.isTaken(username: username).do(onError: { error in
					self?.isUsernameLoading.onNext(false)
				},
				onCompleted: { [weak self] in
					self?.isUsernameLoading.onNext(false)
				}, onSubscribe: {
					self?.isUsernameLoading.onNext(true)
				}).subscribe(onNext: { (isTaken) in
					if isTaken == true {
						observer.onError(registerFormError.usernameTaken)
					}
					else {
						observer.onCompleted()
					}
				}, onError: { (error) in
					observer.onError(error)
				}).disposed(by: self!.disposeBag)
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
		
		guard let username = self.username.value, let password = self.password.value, let confirmPassword = self.confirmPassword.value, try! !isUsernameTaken.value() else {
//			self.notifiableError.value = NotifiableError(title: "Form is not valid".localized(), text: nil)
			return
		}
		
		let email = self.email.value
		let mobile = self.mobile.value

		guard isUsernameValid(username: username) && isPasswordValid(password: password) && password == confirmPassword && isEmailValid(email: email)/* && isMobileValid(mobile: mobile)*/ else {
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
		return RegistrationForm.isUsernameValid(username: username)
	}
	
	private func isPasswordValid(password: String) -> Bool {
		return RegistrationForm.isPasswordValid(password: password)
	}
	
	private func isEmailValid(email: String?) -> Bool {
		
		if email == "" || email == nil {
			return true
		}
		
		return RegistrationForm.isEmailValid(email: email!)
	}
	
	private func isMobileValid(mobile: String?) -> Bool {
		if nil != mobile {
			return String.isPhoneValid(mobile!)
		}
		return true
	}

}
