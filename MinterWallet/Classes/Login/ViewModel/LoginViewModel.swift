//
//  LoginLoginViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift

class LoginViewModel: BaseViewModel {

	var title: String {
		get {
			return "Login".localized()
		}
	}

	override init() {
		super.init()
	}

}
