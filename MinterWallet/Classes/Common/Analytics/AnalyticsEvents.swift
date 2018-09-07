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
	func track(event: Analytics.Event, params: [String : Any]?)
}

class Analytics {
	
	enum Event : String {
		//Screens
		case CoinsScreen
		case SendScreen
		case SendCoinPopupScreen
		case SentCoinPopupScreen
		case ReceiveScreen
		case SettingsScreen
		case TransactionsScreen
		case ConvertSpendScreen
		case ConvertGetScreen
		case AddressesScreen
		case UsernameEditScreen
		case EmailEditScreen
		case PasswordEditScreen
		
		//Coins
		case CoinsUsernameButton
		
		//Events
		//Transaction list
		case TransactionDetailsButton
		case TransactionExplorerButton
		
		//Send Coin
		case SendCoinsChooseCoinButton
		case SendCoinsUseMaxButton
		case SendCoinsSendButton
		case SendCoinsQRButton
		
		//SendCoinPopup
		case SendCoinPopupSendButton
		case SendCoinPopupCancelButton
		
		//SentCoinPopupScreen
		case SentCoinPopupViewTransactionButton
		case SentCoinPopupCloseButton
		
		//ReceiveScreen
		case ReceiveShareButton
		
		//Settings
		case SettingsChangeUserpicButton
		case SettingsLogoutButton
		
		//Addresses
		case AddressesCopyButton
		
		//CovertSpend
		case CovertSpendUseMaxButton
		case CovertSpendExchangeButton
		
		//CovertGet
		case CovertGetExchangeButton
		
	}
	
	//MARK: -
	private var providers: [AnalyticsProvider] = []
	
	init(providers: [AnalyticsProvider]) {
		self.providers = providers
	}
	
	//MARK: -
	
	func track(event: Analytics.Event, params: [String : Any]?) {
		self.providers.forEach { (provider) in
			provider.track(event: event, params: params)
		}
	}
	
}

class AppMetricaAnalyticsProvider : AnalyticsProvider {
	
	//MARK: - Analytics Provider
	
	func track(event: Analytics.Event, params: [String : Any]?) {
		YMMYandexMetrica.reportEvent(event.rawValue, parameters: params) { (error) in
			//error
		}
	}
	
	
	init() {
		YMMYandexMetrica.activate(with: YMMYandexMetricaConfiguration.init(apiKey: "2a367ed1-f289-44bc-8d01-04bdd7d48f6d")!)
	}
	
}
