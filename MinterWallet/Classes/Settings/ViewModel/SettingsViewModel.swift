//
//  SettingsSettingsViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 19/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift
import MinterCore
import MinterMy
import Toucan


class SettingsViewModel: BaseViewModel {
	
	//MARK: -

	var title: String {
		get {
			return "Settings".localized()
		}
	}
	
	private var sections: [BaseTableSectionItem] = []
	
	var showLoginScreen = Variable(false)
	
	var shouldReloadTable = Variable(false)
	
	private var disposeBag = DisposeBag()
	
	private var profileManager: ProfileManager?
	
	private var selectedImage: UIImage?
	
	//MARK: -

	override init() {
		super.init()
		
		Observable.combineLatest(Session.shared.isLoggedIn.asObservable(), Session.shared.user.asObservable()).subscribe(onNext: { [weak self] (_, _) in
			self?.createSections()
			self?.shouldReloadTable.value = true
		}).disposed(by: disposeBag)
		
		createSections()
	}
	
	var rightButtonTitle : String {
		return "Log Out".localized()
	}
	
	//MARK: - Sections
	
	func createSections() {
		
		let user = Session.shared.user.value
		
		var sctns = [BaseTableSectionItem]()
		
		let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell")
		
		if Session.shared.isLoggedIn.value {
			
			let avatar = SettingsAvatarTableViewCellItem(reuseIdentifier: "SettingsAvatarTableViewCell", identifier: "SettingsAvatarTableViewCell")
			
			if nil != selectedImage {
				avatar.avatar = selectedImage
			}
			
			if let avatarURLString = user?.avatar, let avatarURL = URL(string: avatarURLString) {
				avatar.avatarURL = avatarURL
			}
			else {
				if let id = user?.id {
					avatar.avatarURL = MinterMyAPIURL.avatarUserId(id: id).url()
				}
			}
			
			let username = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell", identifier: "DisclosureTableViewCell_Username")
			username.title = "Username".localized()
			username.value = "@" + (user?.username ?? "")
			username.placeholder = "Change"

//			let mobile = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell", identifier: "DisclosureTableViewCell_Mobile")
//			mobile.title = "Mobile".localized()
//			mobile.value = user?.phone
//			mobile.placeholder = "Add"

			let email = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell", identifier: "DisclosureTableViewCell_Email")
			email.title = "Email".localized()
			if let eml = user?.email, eml != "" {
				email.value = eml
			}
			email.placeholder = "Add"
			
			let password = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell", identifier: "DisclosureTableViewCell_Password")
			password.title = "Password".localized()
			password.value = nil
			password.placeholder = "Change"
			
			var items: [BaseCellItem] = []
			
			var section = BaseTableSectionItem(header: "")

			items = [avatar, separator, username, separator, email, separator, password, separator]
			section.items = items
			sctns.append(section)
		}

//		let language = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell", identifier: "DisclosureTableViewCell_Language")
//		language.title = "Language".localized()
//		language.value = "English"
//		language.placeholder = "Change"
//		language.showIndicator = false

		let addresses = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell", identifier: "DisclosureTableViewCell_Addresses")
		addresses.title = "My Addresses".localized()
		addresses.value = nil
		addresses.placeholder = "Manage"
		
		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell", identifier: "ButtonTableViewCell_Transactions")
		button.buttonPattern = "blank"
		button.title = "LOG OUT".localized()
		
		let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell", identifier: "BlankTableViewCell")
		blank.color = .clear
		
		var section1 = BaseTableSectionItem(header: " ")
		section1.items = [addresses, separator, blank, button]
		sctns.append(section1)
		
		sections = sctns
		
	}
	
	//MARK: - Rows
	
	func sectionsCount() -> Int {
		return sections.count
	}
	
	func rowsCount(for section: Int) -> Int {
		return sections[safe: section]?.items.count ?? 0
	}
	
	func cellItem(section: Int, row: Int) -> BaseCellItem? {
		return sections[safe: section]?.items[safe: row]
	}
	
	func section(index: Int) -> BaseTableSectionItem? {
		return sections[safe: index]
	}
	
	//MARK: -
	
	func rightButtonTapped() {
		Session.shared.logout()
	}
	
	//MARK: -
	
	func viewWillAppear() {
		createSections()
		shouldReloadTable.value = true
	}
	
	//MARK: -
	
	func updateAvatar(_ image: UIImage) {
		
		guard let client = APIClient.withAuthentication(), let user = Session.shared.user.value else {
//			self.errorNotification.value = NotifiableError(title: "Something went wrong".localized(), text: nil)
			return
		}
		
		if nil == profileManager {
			profileManager = ProfileManager(httpClient: client)
		}
		
		let toucan = Toucan(image: image).resize(CGSize(width: 500, height: 500), fitMode: Toucan.Resize.FitMode.crop).image
		
		selectedImage = image
		
		self.shouldReloadTable.value = true
		
		if let data = UIImagePNGRepresentation(toucan!) {
			let base64 = data.base64EncodedString()
			
			profileManager?.uploadAvatar(imageBase64: base64, completion: { (succeed, url, error) in
				
				guard nil == error else {
					return
				}
				
				if let user = Session.shared.user.value {
					user.avatar = url?.absoluteString
					Session.shared.user.value = user
				}
				
				Session.shared.loadUser()
				
			})
		}
		
	}

}
