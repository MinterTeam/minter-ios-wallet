//
//  AppSettingsModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 13/11/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import RealmSwift
import BigInt


class AppSettingsDataBaseModel : Object, DatabaseStorageModel {
	
	@objc dynamic var enableSounds: Bool = false
	
}
