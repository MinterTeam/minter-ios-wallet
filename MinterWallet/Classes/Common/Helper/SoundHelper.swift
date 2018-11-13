//
//  SoundHelper.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 07/11/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import AudioToolbox

//Packaged in a .caf, .aif, or .wav file

enum SoundType {
	case click
	case cancel
	case bip
	case refresh
}

class SoundHelper {
	
	static let shared = SoundHelper()
	
	private init() {}
	
	class SoundSettings {
		let fileName: String
		let fileType: String
		var soundID: SystemSoundID
		
		init(fileName: String, fileType: String, soundID: SystemSoundID) {
			self.fileName = fileName
			self.fileType = fileType
			self.soundID = soundID
		}
		
		static var click = SoundSettings(fileName: "pop_zap", fileType: "wav", soundID: 0)
		static var cancel = SoundSettings(fileName: "pop_hi", fileType: "wav", soundID: 0)
		static var bip = SoundSettings(fileName: "beep_digi_octave", fileType: "wav", soundID: 0)
		static var refresh = SoundSettings(fileName: "pop_down", fileType: "wav", soundID: 0)
	}
	
	static func playSound(type soundType: SoundType) {
		var soundSetting: SoundSettings
		switch(soundType) {
		case .click:
			soundSetting = SoundSettings.click
			
		case .cancel:
			soundSetting = SoundSettings.cancel
			
		case .bip:
			soundSetting = SoundSettings.bip
			
		case .refresh:
			soundSetting = SoundSettings.refresh
		}
		
		if soundSetting.soundID == 0 {
			soundSetting.soundID = SoundHelper.registerSoundId(soundSetting)
		}
		AudioServicesPlaySystemSound(soundSetting.soundID)
	}
	
	static func playSoundIfAllowed(type soundType: SoundType) {
		guard AppSettingsManager.shared.isSoundsEnabled else {
			return
		}
		
		playSound(type: soundType)
	}
	
	// MARK: - Private
	
	fileprivate static func registerSoundId(_ soundSetting: SoundSettings) -> SystemSoundID {
		let filePath = Bundle.main.path(forResource: soundSetting.fileName, ofType: soundSetting.fileType)
		let fileURL = URL(fileURLWithPath: filePath!)
		var soundID: SystemSoundID = 0
		AudioServicesCreateSystemSoundID(fileURL as CFURL, &soundID)
		return soundID
	}
}

