//
//  AppSettingsManager.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 13/11/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation


class AppSettingsManager {
	
	enum SettingsKey : String {
		case soundsEnabled
	}
	
	static let shared = AppSettingsManager()
	
	//MARK: -
	
	let database = UserDefaults.standard
	
	var isSoundsEnabled: Bool = true
	
	//MARK: -
	
	private init() {

	}
	
	func restore() {
		if let settings = database.object(forKey: "AppSettings") as? [String : Any] {
			if let sounds = settings[SettingsKey.soundsEnabled.rawValue] as? Bool {
				isSoundsEnabled = sounds
			}
		}
	}
	
	//MARK: -
	
	func setSounds(enabled: Bool) {
		database.set([SettingsKey.soundsEnabled.rawValue : enabled], forKey: "AppSettings")
		database.synchronize()
		
		restore()
	}

}
