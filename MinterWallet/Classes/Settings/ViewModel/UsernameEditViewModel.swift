//
//  UsernameViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 27/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import MinterCore
import MinterMy
import RxSwift
import NotificationBannerSwift


class UsernameEditViewModel : BaseViewModel {
	
	enum usernameFormError : Error {
		case usernameTooShort
		case incorrectUsername
		case usernameTaken
	}
	
	//MARK: -
	
	private let authManager = AuthManager.default
	
	//MARK: -
	
	override init() {
		super.init()
		
		createSection()
		
		isTaken.asObservable().subscribe(onNext: { [weak self] (val) in
			if val {
				self?.state.value = .invalid(error: "USERNAME IS TAKEN".localized())
			}
			else {
				self?.state.value = .default
			}
		}).disposed(by: disposeBag)
		
		username.asObservable().distinctUntilChanged().subscribe({ (username) in
			
			if self.validate() != nil {
				return
			}
			
			self.checkUsername().subscribe(onNext: { (val) in
				
			}, onError: { (err) in
				self.isTaken.value = true
			}, onCompleted: {
				self.isTaken.value = false
			}).disposed(by: self.disposeBag)
			
		}).disposed(by: disposeBag)
		
	}
	
	//MARK: -
	
	var profileManager: ProfileManager?
	
	var errorNotification = Variable<NotifiableError?>(nil)
	
	var successMessage = Variable<NotifiableSuccess?>(nil)
	
	var title: String {
		get {
			return "Username".localized()
		}
	}
	
	private var disposeBag = DisposeBag()
	
	private var isLoading = Variable(false)
	private var isTakenLoading = Variable(false)
	
	private var isTaken = Variable(false)
	
	var username = Variable<String?>(Session.shared.user.value?.username)
	
	var buttonObservable: Observable<Bool> {
		return Observable.combineLatest(isTaken.asObservable(), isLoading.asObservable(), isTakenLoading.asObservable()).map({ (val) -> Bool in
			return !val.0 && !val.1 && !val.2 && (self.username.value ?? "") != (Session.shared.user.value?.username ?? "")
		})
	}
	
	var state = Variable<TextFieldTableViewCell.State>(.default)
	
	//MARK: - TableView
	
	var sections: [BaseTableSectionItem] = []
	
	func createSection() {
		
		var section = BaseTableSectionItem(header: "")
		
		let username = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: "TextFieldTableViewCell_Username")
		username.title = "CHOOSE @USERNAME".localized()
		username.prefix = "@"
		username.value = Session.shared.user.value?.username ?? ""
		username.isLoadingObservable = isTakenLoading.asObservable()
		username.stateObservable = state.asObservable()
		
		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell", identifier: "ButtonTableViewCell")
		button.buttonPattern = "purple"
		button.title = "SAVE".localized()
		button.isLoadingObserver = isLoading.asObservable()
		button.isButtonEnabledObservable = buttonObservable
		
		section.items = [username, button]
		
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
	
	func update(username: String) {
		
		guard LoginForm.isUsernameValid(username: username) && username != (Session.shared.user.value?.username ?? "") else {
			return
		}
		
		guard let client = APIClient.withAuthentication(), let user = Session.shared.user.value else {
			self.errorNotification.value = NotifiableError(title: "Something went wrong".localized(), text: nil)
			return
		}
		
		isLoading.value = true
		
		if nil == profileManager {
			profileManager = ProfileManager(httpClient: client)
		}
		
		user.username = username
		
		profileManager?.updateProfile(user: user, completion: { [weak self] (updated, error) in
			
			self?.isLoading.value = false
			
			guard nil == error else {
				self?.errorNotification.value = NotifiableError(title: "Profile can't be saved".localized(), text: nil)
				return
			}
			
			self?.successMessage.value = NotifiableSuccess(title: "Profile saved".localized(), text: nil)
			
		})
	}
	
	private func checkUsername() -> Observable<Bool> {
		return Observable.create { [weak self] observer in
			if let username = self?.username.value {
				
				if username == Session.shared.user.value?.username {
					observer.onCompleted()
				}

				self?.isTakenLoading.value = true
				
				self?.authManager.isTaken(username: username) { (isTaken, error) in
					
					self?.isTakenLoading.value = false
					
					guard nil == error else {
						observer.onError(error!)
						return
					}

					if isTaken == true {
						observer.onError(usernameFormError.usernameTaken)
					}
					else {
						observer.onCompleted()
					}
				}
			}
			else {
				observer.onError(usernameFormError.incorrectUsername)
			}
			return Disposables.create()
		}
	}
	
	//MARK: -
	
	func validate() -> [String]? {
		if let username = username.value, !isUsernameValid(username: username) {
			return ["USERNAME IS NOT VALID".localized()]
		}
		return nil
	}
	
	//MARK: -
	
	//Move to helper?
	private func isUsernameValid(username: String) -> Bool {
		return LoginForm.isUsernameValid(username: username)
	}

}
