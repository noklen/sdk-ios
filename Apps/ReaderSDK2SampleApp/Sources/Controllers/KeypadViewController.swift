//
//  KeypadViewController.swift
//  ReaderSDK2-SampleApp
//
//  Created by Mike Silvis on 9/25/19.
//

import ReaderSDK2
import ReaderSDK2UI
import UIKit

class KeypadViewController: UIViewController {
    var money: Money {
        didSet {
            chargeButton.money = money
            customAmountEntryView.money = money
        }
    }

    private let theme: Theme

    weak var priceUpdateDelegate: PriceUpdateDelegate? {
        didSet {
            customAmountEntryView.priceUpdateDelegate = priceUpdateDelegate
        }
    }

    private weak var chargeDelegate: ChargeDelegate?

    private lazy var stackView = makeContainerStackView()
    private lazy var chargeButton = makeChargeButton(theme: theme, money: money)
    private lazy var customAmountEntryView = makeCustomAmountEntryView(theme: theme, currency: money.currency)
    private lazy var checkoutStackView = makeCheckoutStackView()

    init(theme: Theme, money: Money, chargeDelegate: ChargeDelegate) {
        self.theme = theme
        self.money = money
        self.chargeDelegate = chargeDelegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ColorGenerator.tertiaryBackgroundColor(theme: theme)
        setupSubviews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func setupSubviews() {
        view.addSubview(stackView)

        stackView.pinToEdges(of: view.safeAreaLayoutGuide)

        let headerStackView = makeHeaderStackview()
        setupHeaderView(headerStackView: headerStackView)
        checkoutStackView.addArrangedSubview(headerStackView)
        checkoutStackView.addArrangedSubview(makeHairlineView(orientation: .horizontal))

        stackView.addArrangedSubview(checkoutStackView)
        stackView.addArrangedSubview(customAmountEntryView)
    }

    private func setupHeaderView(headerStackView: UIStackView) {
        headerStackView.axis = isUsingCompactLayout() ? .vertical : .horizontal

        let titleLabel = makeTitleLabel(title: Strings.TabBar.keypad)
        titleLabel.textAlignment = isUsingCompactLayout() ? .center : .justified
        headerStackView.addArrangedSubview(titleLabel)

        let chargeButtonStackView = makeChargeButtonStackview()
        chargeButtonStackView.addArrangedSubview(chargeButton)
        headerStackView.addArrangedSubview(chargeButtonStackView)
    }

    override func becomeFirstResponder() -> Bool {
        return customAmountEntryView.becomeFirstResponder()
    }
}

extension KeypadViewController {
    private func makeCustomAmountEntryView(theme: Theme, currency: Currency) -> CustomAmountEntryView {
        let view = CustomAmountEntryView(theme: theme, money: money)
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    private func makeContainerStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.distribution = .fill
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }

    private func makeCheckoutStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.spacing = orderEntryDefaultMargin
        stackView.setBackground(color: ColorGenerator.tertiaryBackgroundColor(theme: theme))
        stackView.layoutMargins = UIEdgeInsets(
            top: isUsingCompactLayout() ? 0 : orderEntryDefaultMargin,
            left: 0,
            bottom: 0,
            right: 0
        )

        return stackView
    }

    func makeHeaderStackview() -> UIStackView {
        let stackView = UIStackView()
        stackView.distribution = isUsingCompactLayout() ? .fillEqually : .fill
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(
            top: 0,
            left: orderEntryDefaultMargin,
            bottom: 0,
            right: orderEntryDefaultMargin
        )

        return stackView
    }

    func makeTitleLabel(title: String) -> UILabel {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = theme.titleFont
        titleLabel.textColor = theme.titleColor
        titleLabel.text = title

        return titleLabel
    }

    func makeChargeButton(theme: Theme, money: Money) -> ChargeButton {
        let button = ChargeButton(theme: theme, money: money)
        button.translatesAutoresizingMaskIntoConstraints = false
        if !isUsingCompactLayout() {
            // We want a fixed sized button on non-compact screens. Since we do not support horizontal
            // layout for iPhones, this is applicable only to an iPad.
            button.widthAnchor.constraint(equalToConstant: orderEntryChargeButtonWidthOnIPad).isActive = true
        }
        button.addTarget(self, action: #selector(didTapChargeButton), for: .touchUpInside)

        return button
    }

    func makeChargeButtonStackview() -> UIStackView {
        let stackView = UIStackView()
        stackView.isLayoutMarginsRelativeArrangement = true

        return stackView
    }

    func makeHairlineView(orientation: HairlineView.Orientation) -> HairlineView {
        let view = HairlineView(theme: theme, orientation: orientation)
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    @objc func didTapChargeButton() {
        chargeDelegate?.charge(money)
    }
}
