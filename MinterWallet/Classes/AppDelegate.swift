//
//  AppDelegate.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import MinterCore
import MinterExplorer
import MinterMy

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	let isTestnet = (Bundle.main.infoDictionary?["CFBundleName"] as? String)?.contains("Testnet") ?? false

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

		let conf = Configuration()

		if ProcessInfo.processInfo.arguments.contains("UITesting") {
			MinterGateBaseURLString = "https://tst.gate.minter.network"
			MinterCoreSDK.initialize(urlString: conf.environment.nodeBaseURL, network: isTestnet ? .testnet : .mainnet)
			MinterExplorerSDK.initialize(APIURLString: conf.environment.testExplorerAPIBaseURL,
																	 WEBURLString: conf.environment.testExplorerWebURL,
																	 websocketURLString: conf.environment.testExplorerWebsocketURL)
		} else {
			if !isTestnet {
				MinterGateBaseURLString = "https://gate.apps.minter.network"
			}
			MinterCoreSDK.initialize(urlString: conf.environment.nodeBaseURL, network: isTestnet ? .testnet : .mainnet)
			MinterExplorerSDK.initialize(APIURLString: conf.environment.explorerAPIBaseURL,
																	 WEBURLString: conf.environment.explorerWebURL,
																	 websocketURLString: conf.environment.explorerWebsocketURL)
		}
		MinterMySDK.initialize(network: isTestnet ? .testnet : .mainnet)

		Fabric.with([Crashlytics.self])

		appearance()

		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
	
	func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
		
		if let vc = Router.viewController(by: url) {
			window?.rootViewController?.show(vc, sender: self)
		}
		return true
	}

	// MARK: -

	func appearance() {

		UINavigationBar.appearance().tintColor = .white
		UINavigationBar.appearance().barTintColor = UIColor.mainColor()
		UINavigationBar.appearance().titleTextAttributes = [
			NSAttributedStringKey.foregroundColor: UIColor.white,
			NSAttributedStringKey.font: UIFont.boldFont(of: 18.0)
		]
		if #available(iOS 11.0, *) {
			UINavigationBar.appearance().setTitleVerticalPositionAdjustment(-2, for: .default)
		}

		UIBarButtonItem.appearance().setTitleTextAttributes([
				NSAttributedStringKey.font: UIFont.defaultFont(of: 14),
				NSAttributedStringKey.foregroundColor: UIColor.white,
				NSAttributedStringKey.baselineOffset : 1
			], for: .normal
		)

		UIBarButtonItem.appearance().setTitleTextAttributes([
			NSAttributedStringKey.font: UIFont.defaultFont(of: 14),
			NSAttributedStringKey.foregroundColor : UIColor.white,
			NSAttributedStringKey.baselineOffset : 1
			], for: .highlighted
		)

		UITabBarItem.appearance().titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -2)

		let img = UIImage(named: "BackIcon")?.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0))
		img?.stretchableImage(withLeftCapWidth: 0, topCapHeight: 20)
		UINavigationBar.appearance().backIndicatorTransitionMaskImage = img
		UINavigationBar.appearance().backIndicatorImage = img
		UINavigationBar.appearance().isTranslucent = false

		UITabBarItem.appearance().setTitleTextAttributes([
			NSAttributedStringKey.foregroundColor : UIColor(hex: 0x8A8A8F)!,
			NSAttributedStringKey.font : UIFont.mediumFont(of: 11.0)
		], for: .normal)
		UITabBarItem.appearance().setTitleTextAttributes([
			NSAttributedStringKey.foregroundColor : UIColor.mainColor(),
			NSAttributedStringKey.font : UIFont.mediumFont(of: 11.0)
		], for: .selected)
	}
}
