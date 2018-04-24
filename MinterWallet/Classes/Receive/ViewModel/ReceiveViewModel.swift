//
//  ReceiveReceiveViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 19/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift

class ReceiveViewModel: BaseViewModel {

    var title: String {
      get {
        return "Receive".localized()
        }
    }

    override init() {
	super.init()

    }
}
