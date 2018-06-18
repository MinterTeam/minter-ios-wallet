//
//  RootRootViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 04/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift


class RootViewModel: BaseViewModel {
	
	private let session = Session.shared
	
	private let disposeBag = DisposeBag()

	var title: String {
		get {
			return "Root".localized()
		}
	}

	override init() {
		super.init()
		
		SessionHelper.reloadAccounts()
		
		Session.shared.isLoggedIn.asObservable().subscribe(onNext: { (isLoggedIn) in
			if isLoggedIn {
				//show wallet
				SessionHelper.reloadAccounts()
			}
			else {
				//show login/register
//				if let rootVC = UIViewController.stars_topMostController() as? RootViewController {
//					let vc = Storyboards.Main.instantiateInitialViewController()
//
//					rootVC.showViewControllerWith(vc, usingAnimation: .up) {
//
//					}
//				}
				
			}
		}).disposed(by: disposeBag)
		
		
	}
}
