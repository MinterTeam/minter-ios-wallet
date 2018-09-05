//
//  AnalyticsHelper.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 05/09/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation

class AnalyticsHelper {
	
	static let defaultAnalytics = Analytics(providers: [AppMetricaAnalyticsProvider()])
	
	private init() {}
	
}
