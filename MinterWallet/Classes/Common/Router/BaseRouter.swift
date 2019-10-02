//
//  BaseRouter.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import UIKit

@objc
protocol BaseRouter: class {

	static var patterns: [String] {get}

	static func viewController(path: [String], param: [String: Any]) -> UIViewController?
}

class Router {

	enum ParamType: String {
		case int
		case float
		case string
	}

	// MARK: -

	private init() {}

	static let shared = Router()

	// MARK: -

	static var patterns = [String: AnyClass]()

	static func viewController(by url: URL) -> UIViewController? {

		let routers = Router.shared.getClassesImplementingProtocol(p: BaseRouter.self) as! [BaseRouter.Type]

		var viewController: UIViewController?

		let urlPattern = (url.host ?? "").appending(url.path)

		var matches = false
		var params = [String : Any]()
		var path = [String]()

		let router = routers.filter { (router) -> Bool in
			router.patterns.forEach({ el in

				let (aMatches, aParams, aPath) = Router.shared.matches(pattern: urlPattern, origin: el)

				if aMatches {
					matches = aMatches
					params = aParams
					path = aPath
					return
				}
			})
			return matches
		}.first

		url.params().forEach { (k, v) in
			params[k] = v
		}

		viewController = router?.self.viewController(path: path, param: params)
		return viewController
	}

	private func viewController(viewModel: BaseViewModel) -> BaseViewController? {
		return nil
	}

	private func getClassesImplementingProtocol(p: Protocol) -> [AnyClass] {
		let classes = objc_getClassList()
		var ret = [AnyClass]()

		for cls in classes {
			if class_conformsToProtocol(cls, p) {
				ret.append(cls)
			}
		}
		return ret
	}

	private func objc_getClassList() -> [AnyClass] {
		let expectedClassCount = ObjectiveC.objc_getClassList(nil, 0)
		let allClasses = UnsafeMutablePointer<AnyClass?>.allocate(capacity: Int(expectedClassCount))
		let autoreleasingAllClasses = AutoreleasingUnsafeMutablePointer<AnyClass>(allClasses)
		let actualClassCount:Int32 = ObjectiveC.objc_getClassList(autoreleasingAllClasses, Int32(expectedClassCount))

		var classes = [AnyClass]()
		for i in 0 ..< actualClassCount {
			if let currentClass: AnyClass = allClasses[Int(i)] {
				classes.append(currentClass)
			}
		}

		allClasses.deallocate(capacity: Int(expectedClassCount))
		return classes
	}

	// MARK: -

	private func matches(pattern: String, origin: String) -> (Bool, [String : Any], [String]) {
		let components1 = pattern.components(separatedBy: "/").filter { (str) -> Bool in
			return str != ""
		}

		let components2 = origin.components(separatedBy: "/").filter { (str) -> Bool in
			return str != ""
		}

		let characterSet = CharacterSet.init(charactersIn: "<>")

		//длины путей должнsы быть одинаковыми
		guard components1.count == components2.count else {
			return (false, [:], [])
		}

		var resDict = [String : Any]()
		var resPathDict = [String]()

		for (c1, c2) in zip(components1, components2) {
			if c2.hasPrefix("<") {
				let val = c2.trimmingCharacters(in: characterSet)
				let keyValue = val.components(separatedBy: ":")
				let (key, value) = (keyValue[0], keyValue[1])

				var tempValue: Any?

				let paramType = ParamType(rawValue: key)
				guard paramType != nil else {
					return (false, [:], [])
				}

				switch paramType! {
				case .int:
					tempValue = Int(c1)
					break

				case .float:
					tempValue = Float(c1)
					break

				case .string:
					tempValue = String(c1)
					break
				}

				if tempValue != nil {
					resDict[value] = tempValue
				} else {
					return (false, [:], [])
				}
			} else {
				if c2 != c1 {
					return (false, [:], [])
				}
				else {
					resPathDict.append(c2)
				}
			}
		}
		return (true, resDict, resPathDict)
	}
}

@objc protocol URLInitializable: class {
	static var pattern: String { get }
	static func viewController(params: [String : Any]) -> BaseViewController?
}

extension BaseViewModel {
	static func viewModel(params: [String : Any]) -> BaseViewModel? {
		assert(true, "Should be overriden")
		return nil
	}
}
