//
//  PINManager.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 03/07/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import LocalAuthentication

class PINManager {

	// MARK: -

	enum StorageKeys: String {
		case pin
		case lastDate
	}

	// MARK: -

	static let shared = PINManager()

	private init() {}

	// MARK: -

	private var storage = SecureStorage()

	var isPINset: Bool {
		return nil != (storage.object(forKey: StorageKeys.pin.rawValue) as? Data)
	}

	// MARK: -

	func removePIN() {
		storage.removeObject(forKey: StorageKeys.pin.rawValue)
	}

	func setPIN(code: String) {
		if let data = data(from: code) {
			storage.set(data, forKey: StorageKeys.pin.rawValue)
		}
	}

	func checkPIN(code: String) -> Bool {
		if let object = storage.object(forKey: StorageKeys.pin.rawValue) as? Data {
			return object == data(from: code)
		}
		return false
	}

	private func data(from code: String) -> Data? {
		return code.sha256().data(using: .utf8)
	}

	// MARK: - LocalAuth

	private var authContext = LAContext()

	func canUseBiometric() -> Bool {
		return authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
																				 error: nil)
	}

	@available(iOS 11.0, *)
	func biometricType() -> LABiometryType {
		return authContext.biometryType
	}

	func checkBiometricsIfPossible(with completion: ((Bool) -> ())?) {
		if self.canUseBiometric() {
			self.authContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
																			localizedReason: "To enter to the wallet",
																			reply: { [weak self] (res, err) in
																				self?.authContext.invalidate()
																				self?.authContext = LAContext()
																				completion?(res)
			})
		}
	}

}
