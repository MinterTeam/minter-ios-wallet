//
//  AdvancedModeAdvancedModeViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 26/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift

class AdvancedModeViewModel: BaseViewModel {

	var title: String {
		get {
			return "AdvancedMode".localized()
			}
	}

	override init() {
		super.init()
	}
}
