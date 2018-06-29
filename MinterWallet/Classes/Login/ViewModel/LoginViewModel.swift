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
	
	var notifiableError = Variable<NotifiableError?>(nil)
	
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
		
		isLoading.value = true
		
		authManager.login(username: username, password: accountManager.accountPassword(password)) { [weak self] (accessToken, refreshToken, user, error) in
			
			self?.isLoading.value = false
			
			guard nil == error else {
				
				var errorMessage = ""
				switch error! {
				case .invalidCredentials:
					errorMessage = "Invalid Credentials".localized()
					break
					
				case .custom(let error):
					if nil != error.message {
						errorMessage = error.message!
					}
					else {
						errorMessage = "Something went wrong".localized()
					}
					break
				}
				
				self?.notifiableError.value = NotifiableError(title: errorMessage, text: nil)
				return
			}
			
			guard nil != accessToken && nil != refreshToken else {
				//Show error
				return
			}
			
			self?.accountManager.save(password: password)
			
			SessionHelper.set(accessToken: accessToken, refreshToken: refreshToken, user: user)
			
			AccountManager().save(password: password)
			
		}
		
		
	}

}
