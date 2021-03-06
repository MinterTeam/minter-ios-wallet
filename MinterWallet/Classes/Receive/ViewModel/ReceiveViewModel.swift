//
//  ReceiveReceiveViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 19/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift
import RxCocoa
import PassKit
import MinterCore
import MinterMy

class ReceiveViewModel: BaseViewModel, ViewModelProtocol {

  // MARK: - ViewModelProtocol

  struct Dependency {
    var accounts: Observable<[Account]>
  }

  struct Input {
    var didTapAddPass: AnyObserver<Void>
  }

  struct Output {
    var showViewController: Observable<UIViewController?>
    var errorNotification: Observable<NotifiableError?>
    var isLoadingPass: Observable<Bool>
    var shouldShowPass: Observable<Bool>
  }

  var dependencies: ReceiveViewModel.Dependency!
  var input: ReceiveViewModel.Input!
  var output: ReceiveViewModel.Output!

  // MARK: -

	var title: String {
    return "Receive Coins".localized()
	}

	private var disposableBag = DisposeBag()

	var sections = Variable([BaseTableSectionItem]())

  private var didTapAddPassSubject = PublishSubject<Void>()
  private var showViewControllerSubject = PublishSubject<UIViewController?>()
  private var isLoadingPassSubject = PublishSubject<Bool>()
  private var errorNotificationSubject = PublishSubject<NotifiableError?>()
  private var shouldShowPassSubject = BehaviorRelay(value: PKPassLibrary.isPassLibraryAvailable())

	// MARK: -

	var sectionsObservable: Observable<[BaseTableSectionItem]> {
		return self.sections.asObservable()
	}

  init(dependency: Dependency) {
		super.init()

    self.dependencies = dependency

    input = Input(didTapAddPass: didTapAddPassSubject.asObserver())
    output = Output(showViewController: showViewControllerSubject.asObservable(),
                    errorNotification: errorNotificationSubject.asObservable(),
                    isLoadingPass: isLoadingPassSubject.asObservable(),
                    shouldShowPass: shouldShowPassSubject.asObservable())

    bind()
	}

  var accounts: [Account] = [] {
    didSet {
      self.createSections()
    }
  }

  func bind() {

    didTapAddPassSubject.asObservable().subscribe(onNext: { [weak self] (_) in
      self?.getPass()
    }).disposed(by: disposableBag)

    dependencies
      .accounts.asObservable()
      .subscribe(onNext: { [weak self] (accounts) in
        self?.accounts = accounts
    }).disposed(by: disposableBag)
  }

  // MARK: -

	func createSections() {
		guard let accounts = accounts.first else {
			return
		}

		let sctns = [accounts].map { (account) -> BaseTableSectionItem in
			let sectionId = account.address

			let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
                                                 identifier: "SeparatorTableViewCell_1\(sectionId)")

			let address = AddressTableViewCellItem(reuseIdentifier: "AddressTableViewCell",
                                             identifier: "AddressTableViewCell_" + sectionId)
			address.address = "Mx" + account.address
			address.buttonTitle = "Copy".localized()

			let qrCell = QRTableViewCellItem(reuseIdentifier: "QRTableViewCell",
                                   identifier: "QRTableViewCell")
			qrCell.string = "Mx" + account.address

			var section = BaseTableSectionItem(header: "YOUR ADDRESS".localized())
			section.identifier = sectionId

			section.items = [address, separator, qrCell]
			return section
		}

		self.sections.value = sctns
	}

	// MARK: - Share

	func activities() -> [Any]? {
		guard let account = accounts.first else {
			return nil
		}

		let address = "Mx" + account.address
		return [address]
	}

	// MARK: - TableView

	func section(index: Int) -> BaseTableSectionItem? {
		return sections.value[safe: index]
	}

	func sectionsCount() -> Int {
		return sections.value.count
	}

	func rowsCount(for section: Int) -> Int {
		return sections.value[safe: section]?.items.count ?? 0
	}

	func cellItem(section: Int, row: Int) -> BaseCellItem? {
		return sections.value[safe: section]?.items[safe: row]
	}

  // MARK: -

  let passbookManager = PassbookManager()

  func getPass() {
    guard let account = accounts.first else {
      return
    }

    let address = account.address
    isLoadingPassSubject.onNext(true)
    passbookManager.pass(with: "Mx" + address) { [weak self] (data, error) in
      self?.isLoadingPassSubject.onNext(false)
      guard let passData = data else {
        //show error
        return
      }
      var errorPointer: NSError?
      let pass = PKPass(data: passData, error: &errorPointer)
      if errorPointer == nil {
        let controller = PKAddPassesViewController(pass: pass)
        self?.showViewControllerSubject.onNext(controller)
      }
    }
  }
}
