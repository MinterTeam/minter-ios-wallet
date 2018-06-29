//
//  ReceiveReceiveViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 19/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift
import QRCode


class ReceiveViewModel: BaseViewModel {

	var title: String {
		get {
			return "Receive".localized()
		}
	}
	
	private var disposableBag = DisposeBag()
	
	var sections = Variable([BaseTableSectionItem]())
	
	//MARK: -
	
	var sectionsObservable: Observable<[BaseTableSectionItem]> {
		return self.sections.asObservable()
	}

	override init() {
		super.init()
		
		Session.shared.accounts.asObservable().subscribe(onNext: { [weak self] (accounts) in
			self?.createSections()
		}).disposed(by: disposableBag)
	}
	
	
	func createSections() {
		
		guard let accounts = Session.shared.accounts.value.first else {
			return
		}
		
		let sctns = [accounts].map { (account) -> BaseTableSectionItem in
			let sectionId = account.address
			
			let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell_1\(sectionId)")
			
			let address = ReceiveAddressTableViewCellItem(reuseIdentifier: "ReceiveAddressTableViewCell", identifier: "ReceiveAddressTableViewCell_" + sectionId)
			address.address = "Mx" + account.address
			
			let qr = QRTableViewCellItem(reuseIdentifier: "QRTableViewCell", identifier: "QRTableViewCell")
			qr.string = "Mx" + account.address
			
			var section = BaseTableSectionItem(header: "YOUR ADDRESS".localized())
			section.identifier = sectionId
			
			section.items = [address, separator, qr]
			
			return section
		}
		
		self.sections.value = sctns
		
	}
	
	//MARK: - Share
	
	func activities() -> [Any]? {
		
		guard let account = Session.shared.accounts.value.first else {
			return nil
		}
		
		let address = "Mx" + account.address
		
		let qrCode = QRCode(address)
		if let image = qrCode?.image {
			return [address, image]
		}
		
		return [address]
	}
	
	//MARK: - TableView
	
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
	
}
