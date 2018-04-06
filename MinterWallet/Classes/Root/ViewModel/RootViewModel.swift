//
//  RootRootViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 04/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift

class RootViewModel: BaseViewModel {

    var title: String {
      get {
        return "Root".localized()
        }
    }

    override init() {
	super.init()

    }
}
