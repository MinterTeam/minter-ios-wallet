//
//  LUAutocompleteView.swift
//  LUAutocompleteView
//
//  Created by Laurentiu Ungur on 24/04/2017.
//  Copyright © 2017 Laurentiu Ungur. All rights reserved.
//

/// Highly configurable autocomplete view that is attachable to any `UITextField`.
open class LUAutocompleteView: UIView {
    // MARK: - Public Properties

    /// The object that acts as the data source of the autocomplete view.
    public weak var dataSource: LUAutocompleteViewDataSource?
    /// The object that acts as the delegate of the autocomplete view.
    public weak var delegate: LUAutocompleteViewDelegate?

    /** The time interval responsible for regulating the rate of calling data source function.
    If typing stops for a time interval greater than `throttleTime`, then the data source function will be called.
    Default value is `0.4`.
    */
    public var throttleTime: TimeInterval = 0.4
    /// The maximum height of autocomplete view. Default value is `200.0`.
    public var maximumHeight: CGFloat = 200
    /// A boolean value that determines whether the view should hide after a suggestion is selected. Default value is `true`.
    public var shouldHideAfterSelecting = true
    /** The attributes for the text suggestions.
     
    - Note: This property will be ignored if `autocompleteCell` is not `nil`.
    */
    public var textAttributes: [NSAttributedStringKey: Any]?
    /// The text field to which the autocomplete view will be attached.
    public weak var textField: UITextField? {
        didSet {
            guard let textField = textField else {
                return
            }

            textField.addTarget(self, action: #selector(textFieldEditingChanged), for: .editingChanged)
            textField.addTarget(self, action: #selector(textFieldEditingEnded), for: .editingDidEnd)

            setupConstraints()
        }
    }
    /** A `LUAutocompleteTableViewCell` subclass that will be used to show a text suggestion.
    Set your own in order to customise the appearance.
    Default value is `nil`, which means the default one will be used.
     
    - Note: `textAttributes` will be ignored if this property is not `nil`
    */
    public var autocompleteCell: LUAutocompleteTableViewCell.Type? {
        didSet {
            guard let autocompleteCell = autocompleteCell else {
                return
            }

            tableView.register(autocompleteCell, forCellReuseIdentifier: LUAutocompleteView.cellIdentifier)
            tableView.reloadData()
        }
    }
	
		public var autocompleteCellNibName: String? {
			didSet {
				guard let autocompleteCellNibName = autocompleteCellNibName else {
					return
				}
				
				tableView.register(UINib(nibName: autocompleteCellNibName, bundle: nil), forCellReuseIdentifier: LUAutocompleteView.cellIdentifier)
				tableView.reloadData()
			}
		}
	
    /// The height of each row (that is, table cell) in the autocomplete table view. Default value is `40.0`.
    public var rowHeight: CGFloat = 43.0 {
        didSet {
            tableView.rowHeight = rowHeight
        }
    }

    // MARK: - Private Properties

    private let tableView = UITableView()
    private var heightConstraint: NSLayoutConstraint?
    private static let cellIdentifier = "AutocompleteCellIdentifier"
    private var elements = [String]() {
        didSet {
            tableView.reloadData()
            height = tableView.contentSize.height - 2
        }
    }
    private var height: CGFloat = 0 {
        didSet {
            guard height != oldValue else {
                return
            }

            guard let superview = superview else {
                heightConstraint?.constant = (height > maximumHeight) ? maximumHeight : height
                return
            }
					
						let constant = (self.height > self.maximumHeight) ? self.maximumHeight : self.height
						self.heightConstraint?.constant = constant
					
            UIView.animate(withDuration: 0.2) {
							superview.alpha = (constant == 0) ? 0.0 : 1.0
            }
        }
    }

    // MARK: - Init

    /** Initializes and returns a table view object having the given frame and style.

    - Parameters:
        - frame: A rectangle specifying the initial location and size of the table view in its superview’s coordinates. The frame of the table view changes as table cells are added and deleted.
        - style: A constant that specifies the style of the table view. See `UITableViewStyle` for descriptions of valid constants.

    - Returns: Returns an initialized `UITableView` object, or `nil` if the object could not be successfully initialized.
    */
    public override init(frame: CGRect) {
        super.init(frame: frame)

				commonInit()
    }

    /** Returns an object initialized from data in a given unarchiver.

    - Parameter coder: An unarchiver object.
    
    - Retunrs: `self`, initialized using the data in *decoder*.
    */
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    // MARK: - Private Functions

    private func commonInit() {
			addSubview(tableView)

			tableView.register(UITableViewCell.self, forCellReuseIdentifier: LUAutocompleteView.cellIdentifier)
			tableView.dataSource = self
			tableView.delegate = self
			tableView.rowHeight = rowHeight
			tableView.tableFooterView = UIView()
			tableView.separatorInset = .zero
			tableView.contentInset = .zero
			tableView.showsVerticalScrollIndicator = false
			tableView.showsHorizontalScrollIndicator = false
			tableView.bounces = false
			tableView.backgroundColor = .white
    }

    private func setupConstraints() {
        guard let textField = textField else {
            assertionFailure("Sanity check")
            return
        }

        tableView.removeConstraints(tableView.constraints)
        removeConstraints(self.constraints)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        translatesAutoresizingMaskIntoConstraints = false
			
			self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[tableView]-0-|", options: [], metrics: nil, views: ["tableView" : tableView]))
			self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[tableView]-0-|", options: [], metrics: nil, views: ["tableView" : tableView]))
			
			heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: height)
//			heightConstraint?.priority = .defaultLow
			
			self.addConstraint(heightConstraint!)
    }

    @objc private func textFieldEditingChanged() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(getElements), object: nil)
        perform(#selector(getElements), with: nil, afterDelay: throttleTime)
    }

    @objc private func getElements() {
        guard let dataSource = dataSource else {
            return
        }

        guard let text = textField?.text, !text.isEmpty else {
            elements.removeAll()
            return
        }

        dataSource.autocompleteView(self, elementsFor: text) { [weak self] elements in
            self?.elements = elements
        }
    }

    @objc private func textFieldEditingEnded() {
        height = 0
    }
	
	open override func layoutSubviews() {
		super.layoutSubviews()
		
		if (self.layer.sublayers?.count ?? 0) > 1 {
			self.layer.sublayers?.remove(at: 1)
		}

		if (self.layer.sublayers?.count ?? 0) > 1 {
			self.layer.sublayers?.remove(at: 1)
		}

		layer.applySketchShadow(color: UIColor(hex: 0x502EC2, alpha: 0.1)!, alpha: 1, x: 0, y: 4, blur: 8, spread: 0)
		makeBorderWithCornerRadius(radius: 8, borderColor: UIColor(hex: 0xE1E1E1)!, borderWidth: 1.0)
		
	}
	
}

// MARK: - UITableViewDataSource

extension LUAutocompleteView: UITableViewDataSource {
    /** Tells the data source to return the number of rows in a given section of a table view.

    - Parameters:
        - tableView: The table-view object requesting this information.
        - section: An index number identifying a section of `tableView`.

    - Returns: The number of rows in `section`.
    */
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return !(textField?.text?.isEmpty ?? true) ? elements.count : 0
    }

    /** Asks the data source for a cell to insert in a particular location of the table view.

    - Parameters:
        - tableView: A table-view object requesting the cell.
        - indexPath: An index path locating a row in `tableView`.

    - Returns: An object inheriting from `UITableViewCell` that the table view can use for the specified row. An assertion is raised if you return `nil`.
    */
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LUAutocompleteView.cellIdentifier) else {
            assertionFailure("Cell shouldn't be nil")
            return UITableViewCell()
        }

        guard indexPath.row < elements.count else {
            assertionFailure("Sanity check")
            return cell
        }

        let text = elements[indexPath.row]

        guard let customCell = cell as? LUAutocompleteTableViewCell  else {
            cell.textLabel?.attributedText = NSAttributedString(string: text, attributes: textAttributes)
            cell.selectionStyle = .none

            return cell
        }
			
				customCell.searchTerm = textField?.text

        customCell.set(text: text, searchText: textField?.text)

        return customCell
    }
}

// MARK: - UITableViewDelegate

extension LUAutocompleteView: UITableViewDelegate {
    /** Tells the delegate that the specified row is now selected.

    - Parameters:
        - tableView: A table-view object informing the delegate about the new row selection.
        - indexPath: An index path locating the new selected row in `tableView`.
    */
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < elements.count else {
            assertionFailure("Sanity check")
            return
        }

        if shouldHideAfterSelecting {
            height = 0
        }
        textField?.text = elements[indexPath.row]
        delegate?.autocompleteView(self, didSelect: elements[indexPath.row])
    }
}
