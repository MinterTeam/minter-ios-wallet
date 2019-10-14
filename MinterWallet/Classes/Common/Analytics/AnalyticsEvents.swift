//
//  AnalyticsEvents.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 05/09/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import YandexMobileMetrica

protocol AnalyticsProvider : class {
	func track(event: Analytics.Event, params: [String: Any]?)
}

class Analytics {

	enum Event: String {
		//Screens
		case coinsScreen
		case sendScreen
		case sendCoinPopupScreen
		case sentCoinPopupScreen
		case receiveScreen
		case settingsScreen
		case transactionsScreen
		case convertSpendScreen
		case convertGetScreen
		case addressesScreen
		case usernameEditScreen
		case emailEditScreen
		case passwordEditScreen
		case rawTransactionScreen

		//Coins
		case coinsUsernameButton

		//Events
		//Transaction list
		case transactionDetailsButton
		case transactionExplorerButton

		//Send Coin
		case sendCoinsChooseCoinButton
		case sendCoinsUseMaxButton
		case sendCoinsSendButton
		case sendCoinsQRButton

		//SendCoinPopup
		case sendCoinPopupSendButton
		case sendCoinPopupCancelButton

		//SentCoinPopupScreen
		case sentCoinPopupViewTransactionButton
		case sentCoinPopupShareTransactionButton
		case sentCoinPopupCloseButton

		//ReceiveScreen
		case receiveShareButton

		//Settings
		case settingsChangeUserpicButton
		case settingsLogoutButton

		//Addresses
		case addressesCopyButton

		//ConvertSpend
		case convertSpendUseMaxButton
		case convertSpendExchangeButton

		//ConvertGet
		case convertGetExchangeButton

		//RawTransactionScreen
		case rawTransactionPopupViewTransactionButton
		case rawTransactionPopupShareTransactionButton
		case rawTransactionPopupCloseButton
	}

	// MARK: -

	private var providers: [AnalyticsProvider] = []

	init(providers: [AnalyticsProvider]) {
		self.providers = providers
	}

	// MARK: -

	func track(event: Analytics.Event, params: [String: Any]? = nil) {
		self.providers.forEach { (provider) in
			provider.track(event: event, params: params)
		}
	}
}

class AppMetricaAnalyticsProvider: AnalyticsProvider {

	// MARK: - Analytics Provider

	func track(event: Analytics.Event, params: [String : Any]?) {
		YMMYandexMetrica
			.reportEvent(event.rawValue, parameters: params) { (error) in
			//error
		}
	}

	init() {
		YMMYandexMetrica.activate(with: YMMYandexMetricaConfiguration.init(apiKey: "2a367ed1-f289-44bc-8d01-04bdd7d48f6d")!)
	}
}
