//
//  BannerHelper.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 23/05/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import NotificationBannerSwift

class BannerHelper {

	class func performCopiedNotification(title: String? = nil) {
		let banner = NotificationBanner(title: title ?? "Copied".localized(), subtitle: nil, style: .info)
		banner.duration = 0.3
//		banner.haptic = .none
		banner.show()
	}

}
