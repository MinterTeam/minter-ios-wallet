//
//  Manager+Default.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 22/05/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import MinterCore
import MinterExplorer
import MinterMy


public extension MinterExplorer.TransactionManager {

	class var `default`: MinterExplorer.TransactionManager {
		get {
			let httpClient = APIClient.shared
			let manager = self.init(httpClient: httpClient)
			return manager
		}
	}

}

public extension MinterExplorer.AddressManager {
	
	class var `default`: MinterExplorer.AddressManager {
		get {
			let httpClient = APIClient.shared
			let manager = self.init(httpClient: httpClient)
			return manager
		}
	}
}

public extension MinterMy.InfoManager {
	
	class var `default`: MinterMy.InfoManager {
		get {
			let httpClient = APIClient.shared
			let manager = self.init(httpClient: httpClient)
			return manager
		}
	}
	
}

public extension MinterExplorer.CoinManager {
	class var `default`: MinterExplorer.CoinManager {
		get {
			let httpClient = APIClient.shared
			let manager = self.init(httpClient: httpClient)
			return manager
		}
	}
}
