//
//  AppSettingsManager.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 13/11/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation

class AppSettingsManager {

	// MARK: -

	private static let appSettingsKey = "AppSettings"
	enum SettingsKey: String {
		case sounds
		case fingerprint
	}

	static let shared = AppSettingsManager()

	// MARK: -

	let database = UserDefaults.standard
	var isSoundsEnabled: Bool = true
	var isBiometricsEnabled = false

	// MARK: -

	private init() {}

	func restore() {
		if let settings = database.object(forKey: AppSettingsManager.appSettingsKey) as? [String : Any] {
			if let sounds = settings[SettingsKey.sounds.rawValue] as? Bool {
				isSoundsEnabled = sounds
			}
			if let fingerprint = settings[SettingsKey.fingerprint.rawValue] as? Bool {
				isBiometricsEnabled = fingerprint
			}
		}
	}

	//MARK: -

	func setSounds(enabled: Bool) {
		database.set([SettingsKey.sounds.rawValue : enabled], forKey: AppSettingsManager.appSettingsKey)
		database.synchronize()
		restore()
	}

	func setFingerprint(enabled: Bool) {
		database.set([SettingsKey.fingerprint.rawValue : enabled], forKey: AppSettingsManager.appSettingsKey)
		database.synchronize()
		restore()
	}

}
