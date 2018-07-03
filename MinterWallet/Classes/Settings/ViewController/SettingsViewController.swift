//
//  SettingsSettingsViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 19/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift
import ALCameraViewController


class SettingsViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

	//MARK: - IBOutput
	
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
	
	//MARK: -
	
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

	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		viewModel.viewWillAppear()
	}
	
	private func registerCells() {
		tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil), forCellReuseIdentifier: "SeparatorTableViewCell")
		tableView.register(UINib(nibName: "DisclosureTableViewCell", bundle: nil), forCellReuseIdentifier: "DisclosureTableViewCell")
		tableView.register(UINib(nibName: "DefaultHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "DefaultHeader")
	}
	
	//MARK: - TableView
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return viewModel.sectionsCount()
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return viewModel.rowsCount(for: section)
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		guard let item = self.viewModel.cellItem(section: indexPath.section, row: indexPath.row), let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier, for: indexPath) as? BaseCell else {
			return UITableViewCell()
		}
		
		cell.configure(item: item)
		
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
		
		guard let section = viewModel.section(index: section), section.header != "" else {
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
		}
		else if item.identifier == "DisclosureTableViewCell_Username" {
			self.performSegue(withIdentifier: SettingsViewController.Segue.showUsername.rawValue, sender: self)
		}
		else if item.identifier == "DisclosureTableViewCell_Mobile" {
			self.performSegue(withIdentifier: SettingsViewController.Segue.showMobile.rawValue, sender: self)
		}
		else if item.identifier == "DisclosureTableViewCell_Email" {
			self.performSegue(withIdentifier: SettingsViewController.Segue.showEmail.rawValue, sender: self)
		}
		else if item.identifier == "DisclosureTableViewCell_Password" {
			self.performSegue(withIdentifier: SettingsViewController.Segue.showPassword.rawValue, sender: self)
		}
	}
	
	//MARK: - ImagePicker
	
	func showImagePicker() {
		
		let cropping = CroppingParameters(isEnabled: true, allowResizing: true, allowMoving: true, minimumSize: CGSize(width: 20, height: 20))
		
		let camera = CameraViewController(croppingParameters: cropping, allowsLibraryAccess: true, allowsSwapCameraOrientation: true, allowVolumeButtonCapture: true) { [weak self] (image, asset) in
			
			if let image = image {
				self?.viewModel.updateAvatar(image)
			}
			
			self?.dismiss(animated: true, completion: nil)
		}

		let imagePickerViewController = CameraViewController.imagePickerViewController(croppingParameters: cropping) { [weak self] image, asset in
			if let image = image {
				self?.viewModel.updateAvatar(image)
			}
			
			self?.dismiss(animated: true, completion: nil)
		}
		
		present(imagePickerViewController, animated: true, completion: nil)
		
	}
	
	//MARK: - Segues
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		
	}

}


extension SettingsViewController : SettingsAvatarTableViewCellDelegate {
	
	func didTapChangeAvatar(cell: SettingsAvatarTableViewCell) {
		showImagePicker()
	}
	
}
