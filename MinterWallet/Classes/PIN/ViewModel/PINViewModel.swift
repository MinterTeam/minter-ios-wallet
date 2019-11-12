//
//  PINViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 26/06/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import RxSwift
import LocalAuthentication

class PINViewModel: BaseViewModel, ViewModelProtocol {

	var title: String?
	var desc: String?
	var errorMessage: String?
	var isBiometricEnabled: Bool = false

	// MARK: -

	private var titleSubject: PublishSubject<String> = PublishSubject()
	private var descSubject: PublishSubject<String> = PublishSubject()
	private var viewDidLoadSubject: PublishSubject<Void> = PublishSubject()
	private var viewDidAppearSubject: PublishSubject<Bool> = PublishSubject()

	// MARK: -

	struct Input {
		var viewDidLoad: AnyObserver<Void>
		var viewDidAppear: AnyObserver<Bool>
	}
	struct Output {
		var title: Observable<String>
		var desc: Observable<String>
	}
	struct Dependency {}
	var input: PINViewModel.Input!
	var output: PINViewModel.Output!
	var dependency: PINViewModel.Dependency!

	// MARK: -

	override init() {
		super.init()

		input = Input(viewDidLoad: viewDidLoadSubject.asObserver(),
									viewDidAppear: viewDidAppearSubject.asObserver())
		output = Output(title: titleSubject.asObservable(),
										desc: descSubject.asObservable())
		dependency = Dependency()

		viewDidLoadSubject.subscribe(onNext: { [weak self] (_) in
			self?.titleSubject.onNext(self?.title ?? "")
			self?.descSubject.onNext(self?.desc ?? "")
		}).disposed(by: disposeBag)

		viewDidAppearSubject.subscribe(onNext: { [weak self] (_) in
			if self?.isBiometricEnabled ?? false {
				PINManager.shared.checkBiometricsIfPossible(with: { (res) in
					if res {
						Session.shared.isPINRequired.onNext(false)
					}
				})
			}
		}).disposed(by: disposeBag)
	}

}
