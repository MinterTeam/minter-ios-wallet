//
//  RawTransactionViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 24/09/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import MinterCore
import MinterExplorer
import BigInt
import RxSwift

class RawTransactionViewModel: BaseViewModel, ViewModelProtocol {// swiftlint:disable:this type_body_length cyclomatic_complexity

	// MARK: -

	enum RawTransactionViewModelError: Error {
		case noPrivateKey
		case incorrectTxData
	}

	enum CellIdentifierPrefix: String {
		case fee = "TwoTitleTableViewCell_TransactionFee"
		case separator = "SeparatorTableViewCell"
		case blank = "BlankTableViewCell"
		case button = "ButtonTableViewCell_send"
		case cancelButton = "ButtonTableViewCell_cancel"
	}

	// MARK: - ViewModelProtocol

	struct Input {}
	struct Output {
		var sections: Observable<[BaseTableSectionItem]>
		var shouldClose: Observable<Void>
		var errorNotification: Observable<NotifiableError?>
		var successNotification: Observable<NotifiableSuccess?>
		var vibrate: Observable<Void>
		var popup: Observable<PopupViewController?>
		var lastTransactionExplorerURL: () -> (URL?)
	}
	struct Dependency {
		var account: RawTransactionViewModelAccountProtocol
		var gate: RawTransactionViewModelGateProtocol
	}
	var input: RawTransactionViewModel.Input!
	var output: RawTransactionViewModel.Output!
	var dependency: RawTransactionViewModel.Dependency!

	// MARK: -

	private var cancelButtonDidTapSubject = PublishSubject<Void>()
	private var errorNotificationSubject = PublishSubject<NotifiableError?>()
	private var successNotificationSubject = PublishSubject<NotifiableSuccess?>()
	private var proceedButtonDidTapSubject = PublishSubject<Void>()
	private var sendButtonDidTapSubject = PublishSubject<Void>()
	private var sectionsSubject = ReplaySubject<[BaseTableSectionItem]>.create(bufferSize: 1)
	private var sendingTxSubject = PublishSubject<Bool>()
	private var popupSubject = PublishSubject<PopupViewController?>()
	private var vibrateSubject = PublishSubject<Void>()

	// MARK: -

	private var nonce: BigUInt?
	private var payload: String?
	private var type: RawTransactionType
	private var gasPrice: BigUInt?
	private var gasCoin: String
	private var data: Data?
	private var userData: [String: Any]?

	private var multisendAddressCount = 0
	private var createCoinSymbolCount = 0

	private var fields: [[String: String]] = []
	private var currentGas = BehaviorSubject<Int>(value: RawTransactionDefaultGasPrice)
	private var gasObservable: Observable<String> {
		return currentGas.asObservable()
			.map({ [weak self] (obj) -> String in
				let payloadData = self?.payload?.data(using: .utf8)
				return self?.commissionText(for: obj, payloadData: payloadData) ?? ""
		})
	}
	private let coinFormatter = CurrencyNumberFormatter.coinFormatter
	private let decimalFormatter = CurrencyNumberFormatter.decimalFormatter
	private let noMantissaFormatter = CurrencyNumberFormatter.decimalShortNoMantissaFormatter

	// MARK: -

	init(// swiftlint:disable:this type_body_length cyclomatic_complexity function_body_length
		dependency: Dependency,
		nonce: BigUInt?,
		gasPrice: BigUInt?,
		gasCoin: String?,
		type: RawTransactionType,
		data: Data?,
		payload: String?,
		serviceData: Data?,
		signatureType: Data?,
		userData: [String: Any]? = [:]
	) throws {
		self.dependency = dependency

		self.type = type
		self.gasPrice = gasPrice
		self.gasCoin = gasCoin ?? Coin.baseCoin().symbol!
		self.nonce = nonce
		self.userData = userData

		super.init()

		self.payload = payload
		self.data = data

		try makeFields(data: data)

		self.input = Input()
		self.output = Output(sections: sectionsSubject.asObservable(),
												 shouldClose: cancelButtonDidTapSubject.asObservable(),
												 errorNotification: errorNotificationSubject.asObservable(),
												 successNotification: successNotificationSubject.asObservable(),
												 vibrate: vibrateSubject.asObservable(),
												 popup: popupSubject.asObservable(),
												 lastTransactionExplorerURL: self.lastTransactionExplorerURL)

		sendButtonDidTapSubject.subscribe(onNext: { [weak self] (_) in
			self?.sendTx()
		}).disposed(by: disposeBag)

		proceedButtonDidTapSubject.subscribe(onNext: { [weak self] (_) in
			self?.vibrateSubject.onNext(())
			let viewModel = ConfirmPopupViewModel(desc: "Please confirm transaction sending".localized(),
																						buttonTitle: "CONFIRM AND SEND".localized())
			viewModel.buttonTitle = "CONFIRM AND SEND".localized()
			viewModel.cancelTitle = "CANCEL".localized()
			viewModel.desc = "Press confirm sending transaction".localized()
			viewModel
				.output
				.didTapActionButton
				.asDriver(onErrorJustReturn: ())
				.drive(self!.sendButtonDidTapSubject.asObserver())
				.disposed(by: self!.disposeBag)

			viewModel
				.output
				.didTapCancel
				.asDriver(onErrorJustReturn: ())
				.drive(onNext: { _ in
					self?.popupSubject.onNext(nil)
				})
				.disposed(by: self!.disposeBag)

			self?.sendingTxSubject
				.asDriver(onErrorJustReturn: false)
				.drive(viewModel.input.activityIndicator)
				.disposed(by: self!.disposeBag)

			let popup = PopupRouter.confirmPopupViewController(viewModel: viewModel)
			self?.popupSubject.onNext(popup)
		}).disposed(by: disposeBag)
		self.sectionsSubject.onNext(self.createSections())
	}

	private func sendTx() {
		guard let address = Session.shared.accounts.value.first?.address else {
			return
		}

		Observable.combineLatest(self.dependency.gate.nonce(address: "Mx" + address),
														 self.dependency.gate.minGas())
			.do(onSubscribe: { [weak self] in
				self?.sendingTxSubject.onNext(true)
			}).flatMap({ [weak self] (result) -> Observable<String?> in
				let (nonce, _) = result
				guard let nnnc = BigUInt(decimal: Decimal(nonce+1)),
					let gasCoin = self?.gasCoin,
					let type = self?.type,
					let privateKey = try self?.dependency.account.privatekey()
					else {
						return Observable.error(RawTransactionViewModelError.noPrivateKey)
				}

				let gasPrice = (self?.gasPrice != nil) ? self!.gasPrice! : BigUInt(try self?.currentGas.value() ?? RawTransactionDefaultGasPrice)
				let resultNonce = (self?.nonce != nil) ? self!.nonce! : nnnc

				let tx = RawTransaction(nonce: resultNonce,
																gasPrice: gasPrice,
																gasCoin: gasCoin,
																type: BigUInt(type.rawValue),
																data: self?.data ?? Data(),
																payload: self?.payload?.data(using: .utf8) ?? Data())

				let signedTx = RawTransactionSigner.sign(rawTx: tx, privateKey: privateKey)
				return self?.dependency.gate.send(rawTx: signedTx) ?? Observable<String?>.empty()
			}).subscribe(onNext: { [weak self] (result) in
				self?.lastSentTransactionHash = result
				if let sentViewModel = self?.sentViewModel() {
					let sentViewController = PopupRouter.sentPopupViewCointroller(viewModel: sentViewModel)
					self?.popupSubject.onNext(sentViewController)
				}
				Session.shared.loadTransactions()
				Session.shared.loadBalances()
				Session.shared.loadDelegatedBalance()
				self?.sendingTxSubject.onNext(false)
			}, onError: { [weak self] (error) in
				self?.sendingTxSubject.onNext(false)
				self?.handle(error: error)
				self?.popupSubject.onNext(nil)
			}).disposed(by: disposeBag)
	}

	// MARK: - Sections

	private func createSections() -> [BaseTableSectionItem] {
		var items = [RawTransactionFieldTableViewCellItem]()
		for field in fields {
			let item = RawTransactionFieldTableViewCellItem(reuseIdentifier: "RawTransactionFieldTableViewCell",
																											identifier: "RawTransactionFieldTableViewCell_" + String.random())
			item.title = field["key"]
			item.value = field["value"]
			items.append(item)
		}

		let fee = TwoTitleTableViewCellItem(reuseIdentifier: "TwoTitleTableViewCell",
																				identifier: CellIdentifierPrefix.fee.rawValue)
		fee.title = "Transaction Fee".localized()
		let payloadData = payload?.data(using: .utf8)
		fee.subtitle = self.commissionText(for: 1, payloadData: payloadData)
		fee.subtitleObservable = self.gasObservable

		let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
																							 identifier: CellIdentifierPrefix.separator.rawValue)

		let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
																			 identifier: CellIdentifierPrefix.blank.rawValue)

		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
																				 identifier: CellIdentifierPrefix.button.rawValue)
		button.title = "PROCEED".localized()
		button.buttonPattern = "purple"
		button.output?.didTapButton
			.asDriver(onErrorJustReturn: ())
			.drive(proceedButtonDidTapSubject.asObserver())
			.disposed(by: disposeBag)

		let cancelButton = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
																							 identifier: CellIdentifierPrefix.cancelButton.rawValue)
		cancelButton.title = "CANCEL".localized()
		cancelButton.buttonPattern = "blank"
		cancelButton.output?.didTapButton
			.asDriver(onErrorJustReturn: ())
			.drive(cancelButtonDidTapSubject.asObserver())
			.disposed(by: disposeBag)

		let blank2 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
																				identifier: CellIdentifierPrefix.blank.rawValue + "_2")
		let blank3 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
																				identifier: CellIdentifierPrefix.blank.rawValue + "_3")

		var section = BaseTableSectionItem(header: "")
		section.items = items + [fee, separator, blank, blank2, blank3, button, cancelButton]
		return [section]
	}

	func sentViewModel() -> SentPopupViewModel {
		let vm = SentPopupViewModel()
		vm.actionButtonTitle = "VIEW TRANSACTION".localized()
		vm.secondButtonTitle = "CLOSE".localized()
		vm.title = "Success!".localized()
		vm.noAvatar = true
		vm.desc = "Transaction sent!"
		return vm
	}

	private func commissionText(for gas: Int, payloadData: Data? = nil) -> String {
		let payloadCom = Decimal((payloadData ?? Data()).count) * RawTransaction.payloadByteComissionPrice.decimalFromPIP()
		let commission = (self.type
			.commission(options: [.multisendCount: self.multisendAddressCount,
														.coinSymbolLettersCount: self.createCoinSymbolCount]) + payloadCom)
			.PIPToDecimal() * Decimal(gas)
		let balanceString = CurrencyNumberFormatter.formattedDecimal(with: commission,
																																 formatter: coinFormatter)
		return balanceString + " " + (Coin.baseCoin().symbol ?? "")
	}

	private func handle(error: Error) {
		var notification: NotifiableError
		if let error = error as? HTTPClientError {
			if let errorMessage = error.userData?["log"] as? String {
				notification = NotifiableError(title: "An Error Occurred".localized(),
																			 text: errorMessage)
			} else {
				notification = NotifiableError(title: "An Error Occurred".localized(),
																			 text: "Unable to send transaction".localized())
			}
		} else if let error = error as? RawTransactionViewModelError, error == .noPrivateKey {
			notification = NotifiableError(title: "No private key found".localized())
		} else {
			notification = NotifiableError(title: "An Error Occurred".localized(),
																		 text: "Unable to send transaction".localized())
		}
		self.errorNotificationSubject.onNext(notification)
	}

	var lastSentTransactionHash: String?
	func lastTransactionExplorerURL() -> URL? {
		guard nil != lastSentTransactionHash else {
			return nil
		}
		return URL(string: MinterExplorerBaseURL! + "/transactions/" + (lastSentTransactionHash ?? ""))
	}
}

extension RawTransactionViewModel {

	func makeFields(data: Data?) throws { // swiftlint:disable:this type_body_length cyclomatic_complexity function_body_length
		if let data = data,
			let txData = RLP.decode(data),
			let content = txData[0]?.content {
					switch content {
					case .list(let items, _, _):
						switch type {
						case .sendCoin:
						guard let coinData = items[0].data,
							let coin = String(coinData: coinData),
							let addressData = items[1].data,
							let valueData = items[2].data,
							addressData.toHexString().isValidAddress() else {
								throw RawTransactionViewModelError.incorrectTxData
						}
						let value = BigUInt(valueData)
						let amount = (Decimal(bigInt: value) ?? 0).PIPToDecimal()
						let amountString = CurrencyNumberFormatter.formattedDecimal(with: amount,
																																				formatter: decimalFormatter)
						let sendingValue = amountString + " " + coin
						fields.append(["key": "YOU'RE SENDING".localized(), "value": sendingValue])
						fields.append(["key": "TO".localized(), "value": "Mx" + addressData.toHexString()])

						case .sellCoin:
							fields.append(["key": "TYPE".localized(), "value": "SELL COIN"])
							guard
								let coinFromData = items[0].data,
								let coinFrom = String(coinData: coinFromData),
								let valueData = items[1].data,
								let coinToData = items[2].data,
								let coinTo = String(coinData: coinToData),
								let minimumValueToBuyData = items[2].data,
								coinTo.isValidCoin(),
								coinFrom.isValidCoin() else {
									throw RawTransactionViewModelError.incorrectTxData
							}
							let minimumValueToBuy = BigUInt(minimumValueToBuyData)
							let value = BigUInt(valueData)
							let amountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: value) ?? 0).PIPToDecimal(),
																																					formatter: decimalFormatter)
							fields.append(["key": "COIN FROM".localized(), "value": coinFrom])
							fields.append(["key": "AMOUNT".localized(), "value": amountString])
							fields.append(["key": "COIN TO".localized(), "value": coinTo])

						case .sellAllCoins:
							fields.append(["key": "TYPE".localized(), "value": "SELL ALL"])
							guard let coinFromData = items[0].data,
								let coinFrom = String(coinData: coinFromData),
								let coinToData = items[1].data,
								let coinTo = String(coinData: coinToData),
								let minimumValueToBuyData = items[2].data,
								coinTo.isValidCoin(),
								coinFrom.isValidCoin() else {
									throw RawTransactionViewModelError.incorrectTxData
							}
							fields.append(["key": "COIN FROM".localized(), "value": coinFrom])
							fields.append(["key": "COIN TO".localized(), "value": coinTo])

						case .buyCoin:
							fields.append(["key": "TYPE".localized(), "value": "BUY COIN"])
							guard let coinFromData = items[0].data,
								let coinFrom = String(coinData: coinFromData),
								let valueData = items[1].data,
								let coinToData = items[2].data,
								let coinTo = String(coinData: coinToData),
								let maximumValueToBuyData = items[2].data,
								coinTo.isValidCoin(),
								coinFrom.isValidCoin() else {
									throw RawTransactionViewModelError.incorrectTxData
							}
							let maximumValueToBuy = BigUInt(maximumValueToBuyData)
							let value = BigUInt(valueData)
							let amountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: value) ?? 0).PIPToDecimal(),
																																					formatter: decimalFormatter)
							fields.append(["key": "COIN FROM".localized(), "value": coinFrom])
							fields.append(["key": "AMOUNT".localized(), "value": amountString])
							fields.append(["key": "COIN TO".localized(), "value": coinTo])

						case .createCoin:
							fields.append(["key": "TYPE".localized(), "value": "CREATE COIN"])
							guard let coinNameData = items[0].data,
								let coinName = String(data: coinNameData, encoding: .utf8),
								let coinSymbolData = items[1].data,
								let coinSymbol = String(coinData: coinSymbolData),
								let initialAmountData = items[2].data,
								let initialReserveData = items[3].data,
								let constantReserveRatioData = items[4].data,
								coinSymbol.isValidCoin() else {
									throw RawTransactionViewModelError.incorrectTxData
							}
							self.createCoinSymbolCount = coinSymbol.count
							let initialAmount = BigUInt(initialAmountData)
							let initialReserve = BigUInt(initialReserveData)
							let crr = BigUInt(constantReserveRatioData)
							let initialAmountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: initialAmount) ?? 0).PIPToDecimal(),
																																								 formatter: decimalFormatter)
							let initialReserveString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: initialReserve) ?? 0).PIPToDecimal(),
																																									formatter: decimalFormatter)
							let crrString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: crr) ?? 0),
																																			 formatter: noMantissaFormatter)
							fields.append(["key": "COIN NAME".localized(), "value": coinName])
							fields.append(["key": "COIN SYMBOL".localized(), "value": coinSymbol])
							fields.append(["key": "INITIAL AMOUNT".localized(), "value": initialAmountString])
							fields.append(["key": "INITIAL RESERVE".localized(), "value": initialReserveString])
							fields.append(["key": "CONSTANT RESERVE RATIO".localized(), "value": crrString])

						case .declareCandidacy:
							fields.append(["key": "TYPE".localized(), "value": "DECLARE CANDIDACY".localized()])
							guard
								let addressData = items[0].data,
								let publicKeyData = items[1].data,
								let commissionData = items[2].data,
								let coinData = items[3].data,
								let coin = String(coinData: coinData),
								let stakeData = items[4].data else {
									throw RawTransactionViewModelError.incorrectTxData
							}
							let commission = BigUInt(commissionData)
							let commissionString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: commission) ?? 0),
																																							formatter: noMantissaFormatter)

							let stake = BigUInt(stakeData)
							let amountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: stake) ?? 0).PIPToDecimal(),
																																					formatter: decimalFormatter)
							fields.append(["key": "ADDRESS".localized(), "value": "Mx" + addressData.toHexString()])
							fields.append(["key": "PUBLIC KEY".localized(), "value": "Mp" + publicKeyData.toHexString()])
							fields.append(["key": "COMMISSION".localized(), "value": commissionString])
							fields.append(["key": "COIN".localized(), "value": coin])
							fields.append(["key": "STAKE".localized(), "value": amountString])

						case .delegate:
							fields.append(["key": "TYPE".localized(), "value": "DELEGATE".localized()])
							guard
								let publicKeyData = items[0].data,
								let coinData = items[1].data,
								let coin = String(coinData: coinData),
								let stakeData = items[2].data,
								coin.isValidCoin() else {
									throw RawTransactionViewModelError.incorrectTxData
							}
							let stake = BigUInt(stakeData)
							let amountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: stake) ?? 0).PIPToDecimal(),
																																					formatter: decimalFormatter)
							fields.append(["key": "PUBLIC KEY".localized(), "value": "Mp" + publicKeyData.toHexString()])
							fields.append(["key": "COIN".localized(), "value": coin])
							fields.append(["key": "AMOUNT".localized(), "value": amountString])

						case .unbond:
							fields.append(["key": "TYPE".localized(), "value": "UNBOND".localized()])
							guard
								let publicKeyData = items[0].data,
								let coinData = items[1].data,
								let coin = String(coinData: coinData),
								let stakeData = items[2].data else {
									throw RawTransactionViewModelError.incorrectTxData
							}
							let stake = BigUInt(stakeData)
							let amountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: stake) ?? 0).PIPToDecimal(),
																																					formatter: decimalFormatter)
							fields.append(["key": "PUBLIC KEY".localized(), "value": "Mp" + publicKeyData.toHexString()])
							fields.append(["key": "COIN".localized(), "value": coin])
							fields.append(["key": "AMOUNT".localized(), "value": amountString])

						case .redeemCheck:
							fields.append(["key": "TYPE".localized(), "value": "REDEEM CHECK".localized()])
							guard
								let checkData = items[0].data else {
									throw RawTransactionViewModelError.incorrectTxData
							}
							if let checkPayload = RLP.decode(checkData)?[0]?.content {
								switch checkPayload {
								case .list(let checkPayloadItems, _, _):
									if
										let checkCoinData = checkPayloadItems[safe: 3]?.data,
										let checkAmount = checkPayloadItems[safe: 4]?.data {
										let value = BigUInt(checkAmount)
										let amount = (Decimal(bigInt: value) ?? 0).PIPToDecimal()
										let amountString = decimalFormatter.formattedDecimal(with: amount)
										let checkValue = amountString + " " + (String(coinData: checkCoinData) ?? "")
										fields.append(["key": "AMOUNT".localized(), "value": checkValue])
									}
								case .noItem:
									break
								case .data(_):
									break
								}
							}

							fields.append(["key": "CHECK".localized(), "value": "Mc" + checkData.toHexString()])
							if let proofData = items[1].data, proofData.count > 0 {
								fields.append(["key": "PROOF".localized(), "value": proofData.toHexString()])
							} else if
								let password = userData?["p"] as? String,
								let address = Session.shared.accounts.value.first?.address,
								let proof = RawTransactionSigner.proof(address: address, passphrase: password) {
								self.data = MinterCore.RedeemCheckRawTransactionData(rawCheck: checkData, proof: proof).encode()
								fields.append(["key": "PROOF".localized(), "value": proof.toHexString()])
							} else {
								throw RawTransactionViewModelError.incorrectTxData
							}

						case .setCandidateOnline:
							fields.append(["key": "TYPE".localized(), "value": "SET CANDIDATE ON".localized()])
							guard let publicKeyData = items[0].data else {
								throw RawTransactionViewModelError.incorrectTxData
							}
							fields.append(["key": "PUBLIC KEY".localized(), "value": "Mp" + publicKeyData.toHexString()])

						case .setCandidateOffline:
							fields.append(["key": "TYPE".localized(), "value": "SET CANDIDATE OFF".localized()])
							guard let publicKeyData = items[0].data else {
								throw RawTransactionViewModelError.incorrectTxData
							}
							fields.append(["key": "PUBLIC KEY".localized(), "value": "Mp" + publicKeyData.toHexString()])

						case .createMultisigAddress:
							break
						case .multisend:
							guard
								let arrayData = items[0].data,
								let array = RLP.decode(arrayData) else {
									throw RawTransactionViewModelError.incorrectTxData
							}
							multisendAddressCount = array.count ?? 0
							for idx in 0..<(array.count ?? 0) {
								if
									let addressDictData = array[idx]?.data,
									let addressDict = RLP.decode(addressDictData),
									let coinData = addressDict[0]?.data,
										let coin = String(coinData: coinData),
										let addressData = addressDict[1]?.data,
										let valueData = addressDict[2]?.data {
											let address = addressData.toHexString()
											let value = BigUInt(valueData)
											let amount = (Decimal(bigInt: value) ?? 0).PIPToDecimal()
											let amountString = CurrencyNumberFormatter.formattedDecimal(with: amount,
																																									formatter: decimalFormatter)
											let sendingValue = amountString + " " + coin
											fields.append(["key": "YOU'RE SENDING".localized(), "value": sendingValue])
											fields.append(["key": "TO".localized(), "value": "Mx" + address])
									}
							}

						case .editCandidate:
							fields.append(["key": "TYPE".localized(), "value": "EDIT CANDIDATE".localized()])
							guard let publicKeyData = items[0].data,
								let rewardAddressData = items[1].data,
								let ownerAddressData = items[2].data else {
									throw RawTransactionViewModelError.incorrectTxData
							}
							fields.append(["key": "PUBLIC KEY".localized(), "value": "Mp" + publicKeyData.toHexString()])
							fields.append(["key": "REWARD ADDRESS".localized(), "value": "Mx" + rewardAddressData.toHexString()])
							fields.append(["key": "OWNDER ADDRESS".localized(), "value": "Mx" + ownerAddressData.toHexString()])
						}
						break
					case .noItem: break
					case .data(_): break
					}
					if gasCoin.isValidCoin() {
						fields.append(["key": "GAS COIN".localized(), "value": gasCoin])
					}
					if let payload = payload, payload.count > 0 {
						fields.append(["key": "PAYLOAD MESSAGE".localized(), "value": payload])
					}
			}
	}
}
