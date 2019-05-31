//
//  SettingsSettingsViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 19/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxAppState
import NotificationBannerSwift

class SettingsViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

	// MARK: - IBOutput

	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView?.tableFooterView = UIView()
			tableView.rowHeight = UITableViewAutomaticDimension
			tableView.estimatedRowHeight = 54.0
		}
	}
	@IBAction func logButton(_ sender: Any) {
		viewModel.rightButtonTapped()
	}
	@IBOutlet var bottomView: UIView!
	@IBOutlet weak var infoLabel: UILabel!

	// MARK: -

	var viewModel = SettingsViewModel()

	private var disposeBag = DisposeBag()

	// MARK: Life cycle

	override func viewDidLoad() {
		super.viewDidLoad()

		self.title = viewModel.title

		registerCells()

		//move to VM
		Session.shared.isLoggedIn.asObservable().subscribe(onNext: { [weak self] (isLoggedIn) in
			if let button = self?.navigationItem.rightBarButtonItem?.customView as? UIButton {
				button.setTitle(self?.viewModel.rightButtonTitle, for: .normal)
			}
		}).disposed(by: disposeBag)

		viewModel.showLoginScreen.asObservable().filter({ (val) -> Bool in
			return val == true
		}).subscribe(onNext: { (show) in
			let login = Storyboards.Login.instantiateInitialViewController()
			self.present(UINavigationController(rootViewController: login), animated: true, completion: nil)
		}).disposed(by: disposeBag)

		viewModel.shouldReloadTable.asObservable().filter({ (val) -> Bool in
			return val == true
		}).subscribe(onNext: { [weak self] (val) in
			self?.tableView.reloadData()
		}).disposed(by: disposeBag)

		viewModel.errorNotification.asObservable().filter({ (notification) -> Bool in
			return nil != notification
		}).subscribe(onNext: { (notification) in
			let banner = NotificationBanner(title: notification?.title ?? "", subtitle: notification?.text, style: .danger)
			banner.show()
		}).disposed(by: disposeBag)

		viewModel.successMessage.asObservable().filter({ (notification) -> Bool in
			return nil != notification
		}).subscribe(onNext: { (notification) in
			let banner = NotificationBanner(title: notification?.title ?? "", subtitle: notification?.text, style: .success)
			banner.show()
		}).disposed(by: disposeBag)
		tableView.tableFooterView = bottomView

		if let delegateProxy = UIApplication.shared.delegate as? RxApplicationDelegateProxy,
			let appDele = delegateProxy.forwardToDelegate() as? AppDelegate,
			appDele.isTestnet {

			let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
			let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
			infoLabel.text = "Version: \(version) (\(build))"
		}

		if self.shouldShowTestnetToolbar {
			self.view.addSubview(self.testnetToolbarView)
			self.tableView.contentInset = UIEdgeInsets(top: 57,
																								 left: 0,
																								 bottom: 0,
																								 right: 0)
			self.tableView.contentOffset = CGPoint(x: 0, y: -57)
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		viewModel.viewWillAppear()
		AnalyticsHelper.defaultAnalytics.track(event: .SettingsScreen, params: nil)
	}

	private func registerCells() {
		tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "SeparatorTableViewCell")
		tableView.register(UINib(nibName: "DisclosureTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "DisclosureTableViewCell")
		tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "ButtonTableViewCell")
		tableView.register(UINib(nibName: "BlankTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "BlankTableViewCell")
		tableView.register(UINib(nibName: "SettingsSwitchTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "SwitchTableViewCell")
		tableView.register(UINib(nibName: "DefaultHeader", bundle: nil),
											 forHeaderFooterViewReuseIdentifier: "DefaultHeader")
	}

	// MARK: - TableView

	func numberOfSections(in tableView: UITableView) -> Int {
		return viewModel.sectionsCount()
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return viewModel.rowsCount(for: section)
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		guard let item = self.viewModel.cellItem(section: indexPath.section,
																						 row: indexPath.row),
			let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier,
																							 for: indexPath) as? BaseCell else {
			return UITableViewCell()
		}

		cell.configure(item: item)

		if let buttonCell = cell as? ButtonTableViewCell {
			buttonCell.delegate = self
			buttonCell.backgroundColor = .clear
		}

		if let switchCell = cell as? SwitchTableViewCell {
			switchCell.delegate = self
		}

		let avatarCell = cell as? SettingsAvatarTableViewCell
		avatarCell?.delegate = self

		return cell
	}

	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		guard let section = viewModel.section(index: section) else {
			return UIView()
		}

		let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "DefaultHeader")
		if let defaultHeader = header as? DefaultHeader {
			defaultHeader.titleLabel.text = section.header
		}
		return header
	}

	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		guard let section = viewModel.section(index: section),
			section.header != "" else {

			return 0.1
		}
		return 20
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		guard let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) else {
			return
		}

		if item.identifier == "DisclosureTableViewCell_Addresses" {
			self.performSegue(withIdentifier: SettingsViewController.Segue.showAddress.rawValue, sender: self)
		} else if item.identifier == "DisclosureTableViewCell_Username" {
			self.performSegue(withIdentifier: SettingsViewController.Segue.showUsername.rawValue, sender: self)
		} else if item.identifier == "DisclosureTableViewCell_Mobile" {
			self.performSegue(withIdentifier: SettingsViewController.Segue.showMobile.rawValue, sender: self)
		} else if item.identifier == "DisclosureTableViewCell_Email" {
			self.performSegue(withIdentifier: SettingsViewController.Segue.showEmail.rawValue, sender: self)
		} else if item.identifier == "DisclosureTableViewCell_Password" {
			self.performSegue(withIdentifier: SettingsViewController.Segue.showPassword.rawValue, sender: self)
		}
	}

	// MARK: - ImagePicker

	func showImagePicker(sender: UIView?) {
		let imagePickerController = BaseImagePickerController()
		imagePickerController.delegate = self
		imagePickerController.mediaTypes = ["public.image"]
		let actionSheet = BaseAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		actionSheet.modalPresentationStyle = .overCurrentContext
		if let popoverPresentationController = actionSheet.popoverPresentationController {
			popoverPresentationController.sourceView = sender
			popoverPresentationController.sourceRect = sender?.bounds ?? CGRect.zero
		}

		actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { (action:UIAlertAction) in
			if UIImagePickerController.isSourceTypeAvailable(.camera) {
				imagePickerController.sourceType = .camera
				self.present(imagePickerController, animated: true, completion: nil)
			} else {
//				self.showAlert(withTitle: "Missing camera", andMessage: "You can't take photo, there is no camera.")
			}
		}))
		actionSheet.addAction(UIAlertAction(title: "Choose From Library", style: .default, handler: { (action:UIAlertAction) in
			imagePickerController.sourceType = .photoLibrary
			self.present(imagePickerController, animated: true, completion: nil)
		}))
		actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

		present(actionSheet, animated: true, completion: nil)
	}
}

extension SettingsViewController: SettingsAvatarTableViewCellDelegate {

	func didTapChangeAvatar(cell: SettingsAvatarTableViewCell) {
		AnalyticsHelper.defaultAnalytics.track(event: .SettingsChangeUserpicButton, params: nil)
		showImagePicker(sender: cell)
	}
}

extension SettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		let mediaType = info["UIImagePickerControllerMediaType"] as? String ?? ""
		switch mediaType {
		case "public.movie":
			// TODO: Load video
			picker.dismiss(animated: true, completion: nil)
			break

		case "public.image":
			if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
				self.viewModel.updateAvatar(image)
			}

			picker.dismiss(animated: true, completion: nil)
			break

		default:
			picker.dismiss(animated: true, completion: nil)
			return
		}
	}

	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		picker.dismiss(animated: true, completion: nil)
	}
}

extension SettingsViewController: ButtonTableViewCellDelegate {

	func ButtonTableViewCellDidTap(_ cell: ButtonTableViewCell) {

		hardImpactFeedbackGenerator.prepare()
		hardImpactFeedbackGenerator.impactOccurred()

		if let indexPath = tableView.indexPath(for: cell),
			let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row),
			item.identifier == "ButtonTableViewCell_Get100" {
			SoundHelper.playSoundIfAllowed(type: .bip)
//			viewModel.requestMNT()
			return
		}

		AnalyticsHelper.defaultAnalytics.track(event: .SettingsLogoutButton, params: nil)

		SoundHelper.playSoundIfAllowed(type: .cancel)
		viewModel.rightButtonTapped()
	}
}

extension SettingsViewController: SwitchTableViewCellDelegate {
	func didSwitch(isOn: Bool, cell: SwitchTableViewCell) {
		viewModel.didSwitchSound(isOn: isOn)
	}
}
