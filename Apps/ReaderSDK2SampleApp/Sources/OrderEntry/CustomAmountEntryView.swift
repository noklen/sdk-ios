//
//  CustomAmountEntryView.swift
//  ReaderSDK2-SampleApp
//
//  Created by Kevin Leong on 6/7/19.
//

import ReaderSDK2
import ReaderSDK2UI
import UIKit

class CustomAmountEntryView: UIView {
    var money: Money {
        didSet {
            updateEnteredPriceLabel(with: money)
            priceUpdateDelegate?.didUpdate(money: money)
        }
    }

    private var enteredPriceLabelHeightConstraint: NSLayoutConstraint?

    weak var priceUpdateDelegate: PriceUpdateDelegate?

    private let theme: Theme

    private lazy var containerStackView = makeContainerStackView()
    private lazy var enteredPriceLabel = makeEnteredPriceLabel()
    private lazy var keypadView = makeKeypadView()

    init(theme: Theme, money: Money) {
        self.theme = theme
        self.money = money

        super.init(frame: .zero)

        addSubview(containerStackView)
        containerStackView.addArrangedSubview(enteredPriceLabel)
        containerStackView.addArrangedSubview(HairlineView(theme: theme))
        containerStackView.addArrangedSubview(keypadView)

        applyConstraints()
        updateEnteredPriceLabel(with: Money(amount: 0, currency: money.currency))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }
}

// MARK: - KeypadButtonDelegate
extension CustomAmountEntryView: KeypadButtonDelegate {
    func didTapKeypadButton(value: KeypadButton.Value) {
        switch value {
        case .digit(let digit):
            guard let newAmount = UInt("\(money.amount)\(digit)") else {
                return
            }

            if newAmount != 0 {
                money = Money(amount: newAmount, currency: money.currency)
            }
        case .clear:
            resetEnteredPrice()

        case .empty:
            // no-op.
            break
        }
    }

    @objc func resetEnteredPrice() {
        money = Money(amount: 0, currency: money.currency)
    }
}

// MARK: - UIKeyInput
extension CustomAmountEntryView: UIKeyInput {
    var hasText: Bool {
        return money.amount != 0
    }

    func insertText(_ text: String) {
        switch text {
        case "0"..."9":
            let digit = Int(text)!
            didTapKeypadButton(value: .digit(digit))
        default:
            ()
        }
    }

    func deleteBackward() {
        var amountString = String(money.amount)
        amountString.removeLast()

        if amountString.count == 0 {
            money = Money(amount: 0, currency: money.currency)
        } else {
            money = Money(amount: UInt(amountString)!, currency: money.currency)
        }
    }

    override var inputView: UIView? {
        // Return a dummy view to prevent the system keyboard from appearing
        return UIView()
    }

    override var keyCommands: [UIKeyCommand]? {
        return [
            // Cmd + Backspace
            UIKeyCommand(
                input: "\u{8}",
                modifierFlags: .command,
                action: #selector(resetEnteredPrice),
                discoverabilityTitle: Strings.OrderEntry.clearAmountKeyboardShortcutName
            ),
        ]
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updatePriceLabel(for: traitCollection)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updatePriceLabel(for: traitCollection)
    }
}

// MARK: - Helpers
private extension CustomAmountEntryView {

    // MARK: - Update UI

    func updateEnteredPriceLabel(with amount: Money) {
        enteredPriceLabel.textColor = amount.amount == 0 ? ColorGenerator.disabled(color: theme.titleColor) : theme.titleColor
        enteredPriceLabel.text = amount.description
    }

    // MARK: - Layout

    func applyConstraints() {
        containerStackView.pinToEdges(of: safeAreaLayoutGuide)

        updatePriceLabel(for: traitCollection)
    }

    private func updatePriceLabel(for traitCollection: UITraitCollection) {
        let validSizeClasses: [UIUserInterfaceSizeClass] = [.compact, .regular]

        guard validSizeClasses.contains(traitCollection.horizontalSizeClass) else {
            return
        }

        let enteredPriceLabelHeightToViewHeightRatio: CGFloat = {
            switch traitCollection.horizontalSizeClass {
            case .compact:
                return 0.12
            case .regular:
                return 0.25
            case .unspecified:
                return 0
            @unknown default:
                return 0
            }
        }()

        enteredPriceLabelHeightConstraint?.isActive = false
        enteredPriceLabelHeightConstraint = enteredPriceLabel.heightAnchor.constraint(equalTo: heightAnchor, multiplier: enteredPriceLabelHeightToViewHeightRatio)
        enteredPriceLabelHeightConstraint?.isActive = true
    }

    // MARK: - Factories

    func makeEnteredPriceLabel() -> KeypadEnteredPriceLabel {
        let label = KeypadEnteredPriceLabel(theme: theme)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    func makeKeypadView() -> KeypadView {
        let keypadView = KeypadView(theme: theme, buttonDelegate: self)
        keypadView.translatesAutoresizingMaskIntoConstraints = false
        return keypadView
    }

    func makeContainerStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }
}
