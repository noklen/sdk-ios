//
//  PaymentViewController.swift
//  ReaderSDK2UI
//
//  Created by James Smith on 6/18/19.
//

import ReaderSDK2
import UIKit

/// Prompts the user to pay via the available card entry methods.
/// Starting the payment through the PaymentManager's `startPayment(_:theme:from:delegate:)` method is done in `viewDidLoad()`.
public final class PaymentViewController: UIViewController {
    private let parameters: PaymentParameters
    private let paymentManager: PaymentManager
    private let theme: Theme

    private lazy var cancelButton = makeCancelButton()
    private lazy var titleLabel = makeTitleLabel()
    private lazy var amountLabel = makeAmountLabel()
    private lazy var imageView = makeImageView()
    private lazy var promptLabel = makePromptLabel()
    private lazy var alternativeMethodStackView = makeAlternativePaymentMethodStackView()

    private var paymentHandle: PaymentHandle?
    private weak var delegate: PaymentManagerDelegate?

    public var availableCardInputMethods: CardInputMethods = CardInputMethods() {
        didSet { availableCardInputMethodsDidChange(from: oldValue, to: availableCardInputMethods) }
    }

    /// When a value for both `cardID` and `PaymentParameters.customerID` are present
    /// the button to charge the customer's card on file will be shown.
    public var cardID: String?

    /// Optional token to identify a payment source id used to charge a House Account.
    public var houseAccountPaymentSourceId: String?

    public init(
        parameters: PaymentParameters,
        paymentManager: PaymentManager,
        theme: Theme,
        delegate: PaymentManagerDelegate
    ) {
        self.parameters = parameters
        self.paymentManager = paymentManager
        self.theme = theme
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        paymentManager.remove(self)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = theme.secondaryBackgroundColor
        additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 8, bottom: 8, right: 8)

        view.addSubview(cancelButton)
        view.addSubview(titleLabel)
        view.addSubview(amountLabel)
        view.addSubview(imageView)
        view.addSubview(promptLabel)
        view.addSubview(alternativeMethodStackView)

        setupConstraints()

        availableCardInputMethods = paymentManager.availableCardInputMethods
        paymentManager.add(self)

        paymentHandle = paymentManager.startPayment(
            parameters,
            theme: theme,
            from: self,
            delegate: delegate!
        )

        guard let paymentHandle = paymentHandle else { return }

        for (index, method) in paymentHandle.alternatePaymentMethods.enumerated() {
            let button = makeButton(with: method, tag: index)
            alternativeMethodStackView.addArrangedSubview(button)
        }
    }

    // Handle dismissal via swipe and via tapping cancel button
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let paymentHandle, paymentHandle.isPaymentCancelable {
            paymentHandle.cancelPayment()
        }
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return theme.statusBarStyle
    }

}

// MARK: - AvailableCardInputMethodsObserver
extension PaymentViewController: AvailableCardInputMethodsObserver {

    public func availableCardInputMethodsDidChange(_ cardInputMethods: CardInputMethods) {
        self.availableCardInputMethods = cardInputMethods
    }
}

// MARK: - Helpers
private extension PaymentViewController {

    func availableCardInputMethodsDidChange(from oldCardInputMethods: CardInputMethods, to newCardInputMethods: CardInputMethods) {
        if newCardInputMethods.isEmpty {
            imageView.image = oldCardInputMethods.disconnectedImage
        } else {
            imageView.image = newCardInputMethods.connectedImage
        }
        promptLabel.text = newCardInputMethods.prompt
    }

    func makeCancelButton() -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = theme.tintColor

        let cancelButtonImage = UIImage(
            named: "cancel-button",
            in: .readerSDK2UIResources,
            compatibleWith: nil
        )!

        button.setImage(cancelButtonImage, for: [])
        button.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        return button
    }

    func makeAlternativePaymentMethodStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }

    @objc func cancelButtonPressed() {
        self.dismiss(animated: false)
    }

    func makeButton(with alternatePaymentMethod: AlternatePaymentMethod, tag: Int) -> UIButton {
        let button = AlternatePaymentButton(method: alternatePaymentMethod) { [weak self] method in
            guard let self = self else { return }
            self.didTap(method: method)
        }
        button.tintColor = theme.tintColor
        button.setTitle(alternatePaymentMethod.name, for: .normal)
        return button
    }

    func didTap(method: AlternatePaymentMethod) {
        let paymentSource: PaymentSource? = {
            switch method.type {
            case .cardOnFile:
                guard let cardID = cardID else {
                    present(
                        makeAlert(message: ReaderSDK2UIStrings.Pay.noCardIdErrorMessage),
                        animated: true,
                        completion: nil
                    )

                    return nil
                }

                return CardOnFilePaymentSource(cardID: cardID)
            case .houseAccount:
                guard let houseAccountPaymentSourceId = houseAccountPaymentSourceId else {
                    present(
                        makeAlert(message: ReaderSDK2UIStrings.Pay.noHouseAccountPaymentSourceIdErrorMessage),
                        animated: true,
                        completion: nil
                    )

                    return nil
                }

                return HouseAccountPaymentSource(paymentSourceId: houseAccountPaymentSourceId)
            case .keyed:
                return KeyedCardPaymentSource()
            case .tapToPay:
                return TapToPayPaymentSource()
            default:
                return nil
            }
        }()

        guard let source = paymentSource else { return }

        do {
            try method.triggerPayment(with: source)
        } catch {
            print("Unexpected error occurred: \(error.localizedDescription)")
        }
    }

    func makeTitleLabel() -> UILabel {
        let label = makeLabel(font: .systemFont(ofSize: 16, weight: .black), color: theme.titleColor)
        label.text = ReaderSDK2UIStrings.Pay.totalAmountHeader
        return label
    }

    func makeAmountLabel() -> UILabel {
        let label = makeLabel(font: .systemFont(ofSize: 40, weight: .black), color: theme.subtitleColor)
        label.text = parameters.totalMoney.description
        return label
    }

    func makePromptLabel() -> UILabel {
        return makeLabel(font: .systemFont(ofSize: 22, weight: .black), color: theme.titleColor)
    }

    func makeLabel(font: UIFont, color: UIColor) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = font
        label.textColor = color
        return label
    }

    func makeImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = theme.titleColor
        return imageView
    }

    func setupConstraints() {
        // Contains cancelButton and titleLabel
        let headerLayoutGuide = UILayoutGuide()

        // Contains imageView and promptLabel
        let contentLayoutGuide = UILayoutGuide()

        view.addLayoutGuide(headerLayoutGuide)
        view.addLayoutGuide(contentLayoutGuide)

        NSLayoutConstraint.activate([
            headerLayoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerLayoutGuide.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            headerLayoutGuide.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
            headerLayoutGuide.heightAnchor.constraint(greaterThanOrEqualToConstant: 56.0),

            cancelButton.leadingAnchor.constraint(equalTo: headerLayoutGuide.leadingAnchor),
            cancelButton.topAnchor.constraint(equalTo: headerLayoutGuide.topAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: headerLayoutGuide.bottomAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: headerLayoutGuide.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerLayoutGuide.centerYAnchor),
            titleLabel.widthAnchor.constraint(lessThanOrEqualTo: headerLayoutGuide.widthAnchor),

            amountLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            amountLabel.widthAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.widthAnchor),
            amountLabel.topAnchor.constraint(equalTo: headerLayoutGuide.bottomAnchor),

            contentLayoutGuide.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            contentLayoutGuide.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            contentLayoutGuide.widthAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.9),

            imageView.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),

            promptLabel.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
            promptLabel.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
            promptLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16.0),
            promptLabel.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor),

            alternativeMethodStackView.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
            alternativeMethodStackView.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
            alternativeMethodStackView.topAnchor.constraint(equalTo: promptLabel.bottomAnchor, constant: 16.0),
        ])
    }

    func makeAlert(message: String) -> UIAlertController {
        let alert = UIAlertController(
            title: ReaderSDK2UIStrings.Pay.errorAlertTitle,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: ReaderSDK2UIStrings.Pay.errorAlertOkay, style: .default, handler: nil))

        return alert
    }
}

private extension CardInputMethods {

    var connectedImage: UIImage {
        let magstripeImage = UIImage(
            named: "magstripe",
            in: .readerSDK2UIResources,
            compatibleWith: nil
        )!

        let contactlessImage = UIImage(
            named: "contactless-and-chip",
            in: .readerSDK2UIResources,
            compatibleWith: nil
        )!

        return self == .swipe ? magstripeImage : contactlessImage
    }

    var disconnectedImage: UIImage {
        let magstripeDisconnectedImage = UIImage(
            named: "magstripe-disconnected",
            in: .readerSDK2UIResources,
            compatibleWith: nil
        )!

        let contactlessDisconnected = UIImage(
            named: "contactless-and-chip-disconnected",
            in: .readerSDK2UIResources,
            compatibleWith: nil
        )!

        return self == .swipe ? magstripeDisconnectedImage : contactlessDisconnected
    }

    var prompt: String {

        if self == CardInputMethods([.swipe, .chip, .contactless]) {
            return ReaderSDK2UIStrings.Pay.promptWithInputMethods_swipe_chip_contactless
        }

        if self == CardInputMethods([.swipe, .chip]) {
            return ReaderSDK2UIStrings.Pay.promptWithInputMethods_swipe_chip
        }

        if self == CardInputMethods([.chip, .contactless]) {
            return ReaderSDK2UIStrings.Pay.promptWithInputMethods_chip_contactless
        }

        if self == CardInputMethods([.swipe]) {
            return ReaderSDK2UIStrings.Pay.promptWithInputMethods_swipe
        }

        if self == CardInputMethods([.chip]) {
            return ReaderSDK2UIStrings.Pay.promptWithInputMethods_chip
        }

        return ReaderSDK2UIStrings.Pay.promptWithNoReadersConnected
    }
}
