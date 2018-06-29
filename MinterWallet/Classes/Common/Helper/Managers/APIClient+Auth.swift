//
//  APIClient+Auth.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 19/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import MinterCore

extension APIClient {
	
	class func withAuthentication() -> APIClient? {
		
		guard let accessToken = Session.shared.accessToken else {
			return nil
		}
		
		let client = APIClient(headers: ["Authorization" : "Bearer " + accessToken, "Accept" : "application/json"])
		return client
	}
	
}
