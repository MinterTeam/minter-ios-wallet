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

	private init() {}

	// MARK: -

	let database = UserDefaults.standard
	var isSoundsEnabled: Bool = true
	var isBiometricsEnabled = false

	// MARK: -

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

	// MARK: -

	func setSounds(enabled: Bool) {
		self.isSoundsEnabled = enabled
		save()
	}

	func setFingerprint(enabled: Bool) {
		self.isBiometricsEnabled = enabled
		save()
	}

	func save() {
		database.set([SettingsKey.sounds.rawValue : isSoundsEnabled,
									SettingsKey.fingerprint.rawValue : isBiometricsEnabled],
								 forKey: AppSettingsManager.appSettingsKey)
		database.synchronize()
		restore()
	}

}
