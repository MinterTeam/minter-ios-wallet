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

class SettingsViewModel: BaseViewModel, ViewModelProtocol {

	// MARK: -

	struct Input {
		var pin: AnyObserver<String>
	}
	struct Output {
		var showPINController: Observable<(String, String)>
		var hidePINController: Observable<Void>
		var showConfirmPINController: Observable<(String, String)>
		var shakePINError: Observable<Void>
	}
	struct Dependency {}
	var input: SettingsViewModel.Input!
	var output: SettingsViewModel.Output!
	var dependency: SettingsViewModel.Dependency!

	// MARK: -

	var title: String {
		return "Settings".localized()
	}

	private var sections: [BaseTableSectionItem] = []

	var showLoginScreen = Variable(false)
	var shouldReloadTable = Variable(false)
	private var profileManager: ProfileManager?
	private var selectedImage: UIImage?
	var errorNotification = Variable<NotifiableError?>(nil)
	var successMessage = Variable<NotifiableSuccess?>(nil)

	var isConfirmingPIN = false {
		didSet {
			if !isConfirmingPIN {
				pinString = nil
				pinConfirmationString = nil
			}
		}
	}

	var isCheckingPIN = PINManager.shared.isPINset

	var storage = SecureStorage()

	var pinString: String?
	var pinConfirmationString: String?

	var shouldInstallPIN: Bool {
		return !PINManager.shared.isPINset
	}

	// MARK: -

	private var fingerprintSubject: PublishSubject<Bool> = PublishSubject()
	private var pincodeSubject: PublishSubject<Bool> = PublishSubject()

	// MARK: -

	private var showPINControllerSubject = PublishSubject<(String, String)>()
	private var hidePINControllerSubject = PublishSubject<Void>()
	private var pinSubject = PublishSubject<String>()
	private var showConfirmPINControllerSubject = PublishSubject<(String, String)>()
	private var shakePINErrorSubject = PublishSubject<Void>()

	// MARK: -

	var settingPIN = false

	override init() {
		super.init()

		input = Input(pin: pinSubject.asObserver())
		output = Output(showPINController: showPINControllerSubject.asObservable(),
										hidePINController: hidePINControllerSubject.asObservable(),
										showConfirmPINController: showConfirmPINControllerSubject.asObservable(),
										shakePINError: shakePINErrorSubject.asObservable())
		dependency = Dependency()
		pinSubject.subscribe(onNext: { [weak self] (pin) in
			let isChecking = self?.isCheckingPIN ?? false
			if isChecking {
				Session.shared.checkPin(pin, forChange: isChecking, completion: { (succeed) in
					if succeed {
						self?.isCheckingPIN = false
						if self?.settingPIN ?? false {
							self?.settingPIN = false
							self?.showConfirmPINControllerSubject.onNext(("Set PIN-code".localized(),
																														"Please enter a 4-digit PIN".localized()))
						} else {
							self?.removePIN()
							self?.hidePINControllerSubject.onNext(())
						}
					} else {
						self?.shakePINErrorSubject.onNext(())
					}
				})
			} else if self?.isConfirmingPIN ?? false {
				if self?.confirmPIN(code: pin) ?? false {
					self?.hidePINControllerSubject.onNext(())
				} else {
					self?.shakePINErrorSubject.onNext(())
				}
			} else {
				self?.isConfirmingPIN = true
				self?.setPIN(code: pin)
				self?.showConfirmPINControllerSubject.onNext(("Confirm PIN-code".localized(),
																											"Please confirm your 4-digit PIN".localized()))
			}
		}).disposed(by: disposeBag)

		Observable.combineLatest(Session.shared.isLoggedIn.asObservable(),
														 Session.shared.user.asObservable()).subscribe(onNext: { [weak self] (_, _) in
			self?.createSections()
			self?.shouldReloadTable.value = true
		}).disposed(by: disposeBag)

		createSections()
	}

	var rightButtonTitle: String {
		return "Log Out".localized()
	}

	// MARK: - Sections

	func createSections() {
		let user = Session.shared.user.value

		var sctns = [BaseTableSectionItem]()

		let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
																							 identifier: "SeparatorTableViewCell")
		if Session.shared.isLoggedIn.value {
			let avatar = SettingsAvatarTableViewCellItem(reuseIdentifier: "SettingsAvatarTableViewCell",
																									 identifier: "SettingsAvatarTableViewCell")

			if nil != selectedImage {
				avatar.avatar = selectedImage
			}

			if let avatarURLString = user?.avatar,
				let avatarURL = URL(string: avatarURLString) {
				avatar.avatarURL = avatarURL
			} else {
				if let id = user?.id {
					avatar.avatarURL = MinterMyAPIURL.avatarUserId(id: id).url()
				}
			}

			let username = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell",
																								 identifier: "DisclosureTableViewCell_Username")
			username.title = "Username".localized()
			username.value = "@" + (user?.username ?? "")
			username.placeholder = "Change"

			let email = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell",
																							identifier: "DisclosureTableViewCell_Email")
			email.title = "Email".localized()
			if let eml = user?.email, eml != "" {
				email.value = eml
			}
			email.placeholder = "Add"

			let password = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell",
																								 identifier: "DisclosureTableViewCell_Password")
			password.title = "Password".localized()
			password.value = nil
			password.placeholder = "Change"

			var items: [BaseCellItem] = []

			var section = BaseTableSectionItem(header: "")

			items = [avatar, separator, username, separator, email, separator, password, separator]
			section.items = items
			sctns.append(section)
		}

		let addresses = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell",
																								identifier: "DisclosureTableViewCell_Addresses")
		addresses.title = "My Addresses".localized()
		addresses.value = nil
		addresses.placeholder = "Manage"

		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
																				 identifier: "ButtonTableViewCell_Logout")
		button.buttonPattern = "blank"
		button.title = "LOG OUT".localized()

		let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
																			 identifier: "BlankTableViewCell")
		blank.color = .clear

		let switchItem = SwitchTableViewCellItem(reuseIdentifier: "SwitchTableViewCell",
																						 identifier: "SwitchTableViewCell_Sound")
		switchItem.title = "Enable sounds".localized()
		switchItem.isOn.value = AppSettingsManager.shared.isSoundsEnabled

		let enablePin = SwitchTableViewCellItem(reuseIdentifier: "SwitchTableViewCell",
																						identifier: "SwitchTableViewCell_Pin")
		enablePin.title = "Unlock with PIN-code".localized()
		enablePin.isOn.value = PINManager.shared.isPINset
		enablePin.isOnObservable = pincodeSubject.asObservable()

		let enableBiometrics = SwitchTableViewCellItem(reuseIdentifier: "SwitchTableViewCell",
																									 identifier: "SwitchTableViewCell_Biometrics")

		enableBiometrics.title = "Unlock with fingerprint".localized()
		if #available(iOS 11.0, *) {
			if PINManager.shared.biometricType() == .faceID {
				enableBiometrics.title = "Unlock with FaceID".localized()
			}
		}
		enableBiometrics.isOn.value = AppSettingsManager.shared.isBiometricsEnabled && PINManager.shared.isPINset
		enableBiometrics.isOnObservable = fingerprintSubject.asObservable()

		let changePin = DisclosureTableViewCellItem(reuseIdentifier: "DisclosureTableViewCell",
																								identifier: "DisclosureTableViewCell_ChangePIN")
		changePin.title = "Change PIN-code".localized()
		changePin.value = nil
		changePin.placeholder = ""

		var section1 = BaseTableSectionItem(header: "SECURITY".localized())
		section1.items = [enablePin, separator]

		if PINManager.shared.canUseBiometric() {
			section1.items.append(contentsOf: [enableBiometrics, separator])
		}
		if PINManager.shared.isPINset {
			section1.items.append(contentsOf: [changePin, separator])
		}

		sctns.append(section1)

		var section2 = BaseTableSectionItem(header: "NOTIFICATIONS".localized())
		section2.items = [switchItem, blank, button]
		sctns.append(section2)

		sections = sctns
	}

	// MARK: - Rows

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

	// MARK: -

	func rightButtonTapped() {
		Session.shared.logout()
	}

	// MARK: -

	func viewWillAppear() {
		createSections()
		shouldReloadTable.value = true
		isConfirmingPIN = false
		isCheckingPIN = PINManager.shared.isPINset
	}

	// MARK: -

	func didSwitchSound(isOn: Bool) {
		AppSettingsManager.shared.setSounds(enabled: isOn)
		if isOn {
			SoundHelper.playSoundIfAllowed(type: .click)
		}
	}

	func didSwitchBiometrics(isOn: Bool) {
		AppSettingsManager.shared.setFingerprint(enabled: isOn)
		SoundHelper.playSoundIfAllowed(type: .click)
	}

	func updateAvatar(_ image: UIImage) {

		guard let client = APIClient.withAuthentication(),
			nil != Session.shared.user.value else {
			return
		}

		if nil == profileManager {
			profileManager = ProfileManager(httpClient: client)
		}

		let toucan = Toucan(image: image).resize(CGSize(width: 500, height: 500),
																						 fitMode: Toucan.Resize.FitMode.crop).image

		selectedImage = image

		self.shouldReloadTable.value = true

		if let data = UIImagePNGRepresentation(toucan!) {
			let base64 = data.base64EncodedString()

			profileManager?.uploadAvatar(imageBase64: base64,
																	 completion: { (succeed, url, error) in

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

extension SettingsViewModel {

	func setPIN(code: String) {
		self.pinString = code
	}

	func confirmPIN(code: String) -> Bool {

		guard nil != self.pinString else {
			return false
		}

		if self.pinString == code {
			//save PIN
			PINManager.shared.setPIN(code: code)
			pincodeSubject.onNext(true)
			return true
		}
		return false
	}

	func removePIN() {
		PINManager.shared.removePIN()
		AppSettingsManager.shared.setFingerprint(enabled: false)
		fingerprintSubject.onNext(false)
	}

	func checkPin(_ code: String) -> Bool {
		return PINManager.shared.checkPIN(code: code)
	}

	func pinViewModel() -> PINViewModel {
		let viewModel = PINViewModel()
		viewModel.title = self.isCheckingPIN ? "Current PIN-code".localized() : "Set PIN-code".localized()
		viewModel.desc = "Please enter a 4-digit PIN".localized()
		return viewModel
	}
}
