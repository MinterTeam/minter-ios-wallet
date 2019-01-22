//
//  LoginLoginViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift
import MinterCore
import MinterMy



class LoginViewModel: BaseViewModel {

	var title: String {
		get {
			return "Sign In".localized()
		}
	}

	private var sections: [BaseTableSectionItem] = []
	
	private var authManager = AuthManager.default
	private var accountManager = AccountManager()
	
	var isLoading = Variable(false)
	
	var username = Variable<String?>(nil)
	var password = Variable<String?>(nil)
	
	var notifiableError = Variable<NotifiableError?>(nil)
	
	private let disposeBag = DisposeBag()
	
	var isButtonEnabled: Observable<Bool> {
		return Observable.combineLatest(username.asObservable(), password.asObservable()).map({ (val) -> Bool in
			return LoginForm.isUsernameValid(username: val.0 ?? "") && LoginForm.isPasswordValid(password: (val.1 ?? ""))
		})
	}
	
	//MARK: -
	
	override init() {
		super.init()
		
		createSection()
	}
	
	func createSection() {
		let username = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: "TextFieldTableViewCell_Username")
		username.title = "YOUR @USERNAME".localized()
		username.prefix = "@"
		
		let password = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: "TextFieldTableViewCell_Password")
		password.title = "YOUR PASSWORD".localized()
		password.isSecure = true
		
		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell", identifier: "ButtonTableViewCell")
		button.title = "CONTINUE".localized()
		button.buttonPattern = "purple"
		button.isLoadingObserver = self.isLoading.asObservable()
		button.isButtonEnabledObservable = self.isButtonEnabled
		button.isButtonEnabled = false
		
		var section = BaseTableSectionItem(header: "")
		section.items = [username, password, button]
		sections.append(section)

	}
	
	//MARK: -
	
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
	
	func login(username: String, password: String) {
		
		let pwd = accountManager.accountPassword(password)
		
		authManager.login(username: username, password: pwd).do(onSubscribe: { [weak self] in
			self?.isLoading.value = true
		}).subscribe(onNext: { [weak self] (res) in
			self?.accountManager.save(password: password)

			SessionHelper.set(accessToken: res.0, refreshToken: res.1, user: res.2)

			AccountManager().save(password: password)
		}, onError: { [weak self] (error) in
			var errorMessage = ""
			if let error = error as? AuthManager.AuthManagerLoginError {
			
				switch error {
				case .invalidCredentials:
					errorMessage = "Invalid Credentials".localized()
					break

				case .custom(let error):
					if nil != error.message {
						errorMessage = error.message!
					}
					break
				}
			}
			
			if errorMessage == "" {
				errorMessage = "Something went wrong".localized()
			}
			self?.notifiableError.value = NotifiableError(title: errorMessage, text: nil)
		}, onCompleted: { [weak self] in

		}) { [weak self] in
			self?.isLoading.value = false
		}.disposed(by: disposeBag)
		
	}

}
