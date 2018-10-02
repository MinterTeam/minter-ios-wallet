//
//  HomeViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 28/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import SafariServices


class HomeViewController: BaseViewController {
	
	//MARK: Life cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController?.setNavigationBarHidden(true, animated: animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		self.navigationController?.setNavigationBarHidden(false, animated: animated)
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	@IBAction func didTapHelpButton(_ sender: Any) {
		//TODO: Move somewhere
		let url = URL(string: "https://help.minter.network")!
		let vc = SFSafariViewController(url: url)
		self.present(vc, animated: true, completion: nil)
	}
	
	//MARK: -
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		
		if segue.identifier == "showAdvanced" {
			if let advanced = segue.destination as? AdvancedModeViewController {
				advanced.delegate = self
			}
		}
	}
}


extension HomeViewController : AdvancedModeViewControllerDelegate {
	
	func AdvancedModeViewControllerDidAddAccount() {
		
		if let rootVC = UIViewController.stars_topMostController() as? RootViewController {
			let vc = Storyboards.Main.instantiateInitialViewController()
			rootVC.showViewControllerWith(vc, usingAnimation: .up) {
				
			}
		}
	}
	
}
