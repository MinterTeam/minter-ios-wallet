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
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	let isTestnet = (Bundle.main.infoDictionary?["CFBundleName"] as? String)?.contains("Testnet") ?? false

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

		UITextViewWorkaround.executeWorkaround()

		let conf = Configuration()

		if ProcessInfo.processInfo.arguments.contains("UITesting") {
			MinterGateBaseURLString = "https://qa.gate-api.minter.network"
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
		
		// this line is important
		self.window = UIWindow(frame: UIScreen.main.bounds)

		// In project directory storyboard looks like Main.storyboard,
		// you should use only part before ".storyboard" as it's name,
		// so in this example name is "Main".
		let rootVC = Storyboards.Root.instantiateInitialViewController()
		rootVC.viewModel = RootViewModel()
		self.window?.rootViewController = rootVC
		self.window?.makeKeyAndVisible()
		appearance()

		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
	}

	func applicationWillTerminate(_ application: UIApplication) {
	}

	var applicationOpenWithURL = PublishSubject<Void>()
	func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
		applicationOpenWithURL.onNext(())
		(window?.rootViewController as? RootViewController)?.viewModel.input.proceedURL.onNext(url)
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
				NSAttributedStringKey.baselineOffset: 1
			], for: .normal
		)

		UIBarButtonItem.appearance().setTitleTextAttributes([
			NSAttributedStringKey.font: UIFont.defaultFont(of: 14),
			NSAttributedStringKey.foregroundColor: UIColor.white,
			NSAttributedStringKey.baselineOffset: 1
			], for: .highlighted
		)

		UITabBarItem.appearance().titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -2)

		let img = UIImage(named: "BackIcon")?.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0))
		img?.stretchableImage(withLeftCapWidth: 0, topCapHeight: 20)
		UINavigationBar.appearance().backIndicatorTransitionMaskImage = img
		UINavigationBar.appearance().backIndicatorImage = img
		UINavigationBar.appearance().isTranslucent = false

		UITabBarItem.appearance().setTitleTextAttributes([
			NSAttributedStringKey.foregroundColor: UIColor(hex: 0x8A8A8F)!,
			NSAttributedStringKey.font : UIFont.mediumFont(of: 11.0)
		], for: .normal)
		UITabBarItem.appearance().setTitleTextAttributes([
			NSAttributedStringKey.foregroundColor : UIColor.mainColor(),
			NSAttributedStringKey.font : UIFont.mediumFont(of: 11.0)
		], for: .selected)
	}
}
