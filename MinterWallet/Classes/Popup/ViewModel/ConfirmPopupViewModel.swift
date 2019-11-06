//
//  ConfirmPopupViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 11/10/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import RxSwift

class ConfirmPopupViewModel: PopupViewModel, ViewModelProtocol {

	// MARK: - ViewModelProtocol

	struct Input {
		var didTapAction: AnyObserver<Void>
		var didTapCancel: AnyObserver<Void>
		var activityIndicator: AnyObserver<Bool>
	}
	struct Output {
		var isActivityIndicatorAnimating: Observable<Bool>
		var description: String?
		var didTapActionButton: Observable<Void>
		var didTapCancel: Observable<Void>
	}
	struct Dependency {}
	var input: ConfirmPopupViewModel.Input!
	var output: ConfirmPopupViewModel.Output!
	var dependency: ConfirmPopupViewModel.Dependency!

	// MARK: -

	var desc: String?
	var buttonTitle: String?
	var cancelTitle: String?

	// MARK: -

	private var didTapActionSubject = PublishSubject<Void>()
	private var didTapCancelSubject = PublishSubject<Void>()
	private var activityIndicatorSubject = PublishSubject<Bool>()

	init(desc: String?, buttonTitle: String? = nil, cancelTitle: String? = nil) {
		super.init()

		input = Input(didTapAction: didTapActionSubject.asObserver(),
									didTapCancel: didTapCancelSubject.asObserver(),
									activityIndicator: activityIndicatorSubject.asObserver())
		output = Output(isActivityIndicatorAnimating: activityIndicatorSubject.asObservable(),
										description: desc,
										didTapActionButton: didTapActionSubject.asObservable(),
										didTapCancel: didTapCancelSubject.asObservable())
		dependency = Dependency()
	}
}
