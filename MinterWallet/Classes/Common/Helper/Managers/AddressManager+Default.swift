//
//  AddressManager+Default.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 15/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import MinterMy
import MinterCore

public extension MyAddressManager {

	class func manager(accessToken: String) -> MyAddressManager {
		let client = APIClient(headers: ["Authorization": accessToken])
		return MyAddressManager(httpClient: client)
	}
}
