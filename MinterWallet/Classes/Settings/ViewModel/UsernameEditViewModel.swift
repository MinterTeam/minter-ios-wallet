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
	
	//MARK: -
	
	override init() {
		super.init()
		
		createSection()
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
	
	private var isLoading = Variable(false)
	
	//MARK: - TableView
	
	var sections: [BaseTableSectionItem] = []
	
	func createSection() {
		
		var section = BaseTableSectionItem(header: "")
		
		let username = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: "TextFieldTableViewCell_Username")
		username.title = "CHOOSE @USERNAME".localized()
		username.prefix = "@"
		username.value = Session.shared.user.value?.username ?? ""
		
		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell", identifier: "ButtonTableViewCell")
		button.buttonPattern = "purple"
		button.title = "SAVE".localized()
		button.isLoadingObserver = isLoading.asObservable()
		
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
		
		guard String.isUsernameValid(username) && username != (Session.shared.user.value?.username ?? "") else {
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
	
	//MARK: -

}
