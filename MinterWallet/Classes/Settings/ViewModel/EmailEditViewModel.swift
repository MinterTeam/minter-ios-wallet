//
//  EmailEditViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 27/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import MinterCore
import MinterMy
import RxSwift

class EmailEditViewModel: BaseViewModel {
	
	//MARK: - Input
	
	var email: AnyObserver<String>
	private var emailSubject = PublishSubject<String>()
	
	var saveInDidTap: AnyObserver<Void>
	private var saveInDidTapSubject = PublishSubject<Void>()
	
	var emailErrors = PublishSubject<String?>()
	
	
	//MARK: -
	
	private var profileManager: ProfileManager!
	
	var errorNotification = Variable<NotifiableError?>(nil)
	
	var successMessage = Variable<NotifiableSuccess?>(nil)
	
	//MARK: -
	
	private var isLoading = Variable(false)
	
	var isButtonEnabled = Variable(false)
	var state = Variable(TextFieldTableViewCell.State.default)
	
	//MARK: -
	
	override init() {
		
		let client = APIClient.withAuthentication()
		let user = Session.shared.user.value
		
		email = emailSubject.asObserver()
		saveInDidTap = saveInDidTapSubject.asObserver()
		
		super.init()
		
		if client == nil || user == nil {
			self.errorNotification.value = NotifiableError(title: "Something went wrong".localized(), text: nil)
			return
		}
		
		profileManager = ProfileManager(httpClient: client!)
		
		createSection()
		
		emailSubject.asObservable().distinctUntilChanged().subscribe { [weak self] el in
			if let emailString = el.element, !emailString.isEmpty {
				self?.emailErrors.onNext(self?.validate(email: emailString)?.first)
			}
			else {
				self?.emailErrors.onNext(nil)
			}
			
			if (el.element?.isValidEmail() ?? false) && (el.element ?? "") != (Session.shared.user.value?.email ?? "") {
				self?.isButtonEnabled.value = true
			}
			else {
				self?.isButtonEnabled.value = false
			}
		}.disposed(by: disposeBag)
		
		saveInDidTapSubject
			.withLatestFrom(emailSubject.asObservable())
			.filter({ (eml) -> Bool in
				return eml.isValidEmail() && eml != (Session.shared.user.value?.email ?? "")
			}).subscribe(onNext: { [weak self] (em) in
				
				guard self != nil else { return }
				
				var newUser = user
				newUser?.email = em
				
				self?.profileManager.updateProfile(user: newUser!).subscribe(onNext: { [weak self] (val) in
					Session.shared.user.value = newUser
					self?.successMessage.value = NotifiableSuccess(title: "Profile saved".localized(), text: nil)
				}, onError: { [weak self] (error) in
					var message = "Profile can't be saved".localized()
					if let err = error as? HTTPClientError, let mes = err.userData?["message"] as? String {
						message = mes
					}
					self?.errorNotification.value = NotifiableError(title: message, text: nil)
				}, onCompleted: { [weak self] in
					self?.isLoading.value = false
				}).disposed(by: self!.disposeBag)
			}).disposed(by: disposeBag)
		
	}
	
	//MARK: -
	
	var title: String {
		get {
			return "Email".localized()
		}
	}
	
	//MARK: - TableView
	
	var sections: [BaseTableSectionItem] = []
	
	func createSection() {
		
		var section = BaseTableSectionItem(header: "", items: [])
		
		let email = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: "TextFieldTableViewCell_Email")
		email.title = "EMAIL (OPTIONAL *)".localized()
		email.value = Session.shared.user.value?.email
		email.keyboardType = .emailAddress
		email.stateObservable = state.asObservable()
		
		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell", identifier: "ButtonTableViewCell")
		button.buttonPattern = "purple"
		button.title = "SAVE".localized()
		button.isLoadingObserver = isLoading.asObservable()
		button.isButtonEnabledObservable = isButtonEnabled.asObservable()
		button.isButtonEnabled = false
		
		section.items = [email, button]
		
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
	
	func validate(email: String) -> [String]? {
		if !email.isValidEmail() {
			return ["EMAIL IS NOT VALID".localized()]
		}
		return nil
	}

}
