//
//  EmailEditViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 27/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation


class EmailEditViewModel: BaseViewModel {
	
	//MARK: -
	
	override init() {
		super.init()
		
		createSection()
	}
	
	//MARK: -
	
	var title: String {
		get {
			return "Email".localized()
		}
	}
	
	//MARK: - TableView
	
	var sections: [BaseTableSectionItem] = []
	
	func createSection() {
		
		let section = BaseTableSectionItem()
		section.title = "".localized()
		
//		let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell")
		
		let email = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: "TextFieldTableViewCell_Email")
		email.title = "EMAIL (OPTIONAL *)".localized()
		
		section.cells = [email]
		
		sections.append(section)
		
	}
	
	func section(index: Int) -> BaseTableSectionItem? {
		return sections[safe: index]
	}
	
	func sectionsCount() -> Int {
		return sections.count
	}
	
	func rowsCount(for section: Int) -> Int {
		return sections[safe: section]?.cells.count ?? 0
	}
	
	func cellItem(section: Int, row: Int) -> BaseCellItem? {
		return sections[safe: section]?.cells[safe: row]
	}
	
	//MARK: -
	
}
