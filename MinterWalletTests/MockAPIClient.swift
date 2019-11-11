//
//  MockAPIClient.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 07/02/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import MinterCore

class MockAPIClient {

}

extension MockAPIClient : HTTPClient {
	
	// MARK: - Protocol methods
	
	public func postRequest(_ URL: URL, parameters: [String: Any]?, completion: HTTPClient.CompletionBlock?) {
		
	}
	
	public func getRequest(_ URL: URL, parameters: [String: Any]?, completion: HTTPClient.CompletionBlock?) {
		if URL.absoluteString == "" {
			
			let resp = HTTPClient.HTTPClientResponse(200, [], [:], [:])
			
			completion?(resp, nil)
		}
	}
	
	public func putRequest(_ URL: URL, parameters: [String: Any]?, completion: HTTPClient.CompletionBlock?) {
		
	}
	
	public func deleteRequest(_ URL: URL, parameters: [String: Any]?, completion: HTTPClient.CompletionBlock?) {
		
	}
	
}
