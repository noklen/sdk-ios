//
//  OrderEntryViewController.swift
//  ReaderSDK2-SampleApp
//
//  Created by Mike Silvis on 9/25/19.
//

import ReaderSDK2
import ReaderSDK2UI
import UIKit

protocol OrderEntryViewControllerDelegate: AnyObject {
    func orderEntryViewControllerDidInitiateLogout(_ orderEntryViewController: OrderEntryViewController)
}

class OrderEntryViewController: UINavigationController {

    private var money: Money {
        didSet {
            if money != oldValue {
                keypadViewController.money = money
            }
        }
    }

    private let theme: Theme
    private let authorizationManager: AuthorizationManager
    private let paymentManager: PaymentManager
    private lazy var keypadViewController = KeypadViewController(theme: theme, money: money, chargeDelegate: self)
    private weak var orderEntryViewControllerDelegate: OrderEntryViewControllerDelegate?

    init(theme: Theme, authorizationManager: AuthorizationManager, paymentManager: PaymentManager, delegate: OrderEntryViewControllerDelegate) {
        self.theme = theme
        self.authorizationManager = authorizationManager
        self.paymentManager = paymentManager
        self.orderEntryViewControllerDelegate = delegate
        self.money = Money(amount: 0, currency: authorizationManager.authorizedLocation?.currency ?? .USD)

        super.init(nibName: nil, bundle: nil)

        viewControllers = [keypadViewController]

        keypadViewController.priceUpdateDelegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ColorGenerator.secondaryBackgroundColor(theme: theme)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        _ = keypadViewController.becomeFirstResponder()
    }
}

extension OrderEntryViewController: PriceUpdateDelegate {
    func didUpdate(money: Money) {
        self.money = money
    }
}

extension OrderEntryViewController: ChargeDelegate {
    func charge(_ money: Money) {
        let parameters = Config.parameters
        parameters.amountMoney = money

        let paymentViewController = PaymentViewController(
            parameters: parameters,
            paymentManager: paymentManager,
            theme: theme,
            delegate: self
        )
        paymentViewController.cardID = Config.CardOnFile.cardID

        let navigationController = UINavigationController(
            rootViewController: paymentViewController
        )
        navigationController.isNavigationBarHidden = true
        navigationController.modalPresentationStyle = .fullScreen

        present(navigationController, animated: true, completion: nil)
    }
}

// MARK: - PaymentManagerDelegate

extension OrderEntryViewController: PaymentManagerDelegate {

    func paymentManager(_ paymentManager: PaymentManager, didFinish payment: Payment) {
        guard let presentingNavigationConroller = presentedViewController as? UINavigationController else {
            return
        }

        print("Finished payment with ID: \(payment.id!) status: \(payment.status.description)")

        // Reset the money required for this order
        money = Money(amount: 0, currency: authorizationManager.authorizedLocation?.currency ?? .USD)
        Config.parameters = PaymentParameters(amountMoney: money)

        // Show transaction complete
        let transactionComplete = TransactionCompleteViewController(theme: theme, payment: payment)
        presentingNavigationConroller.setViewControllers([transactionComplete], animated: true)
    }

    func paymentManager(_ paymentManager: PaymentManager, didFail payment: Payment, withError error: Error) {
        switch error {
        case Errors.Payment.paymentAlreadyInProgress:
            // do not dismiss the current view controller since the current payment is using the view controller, however log the error
            print(error)
        case Errors.Payment.notAuthorized:
            dismiss(animated: true, completion: self.showLogoutAlert)
        case Errors.Payment.timedOut:
            dismiss(animated: true, completion: nil)
        default:
            dismiss(animated: true) { self.showErrorAlert(error) }
        }
    }

    func paymentManager(_ paymentManager: PaymentManager, didCancel payment: Payment) {
        dismiss(animated: true, completion: nil)
    }
}

private extension OrderEntryViewController {

    func showLogoutAlert() {
        let alert = UIAlertController(title: "Not Authorized", message: "Please log in again.", preferredStyle: .alert)
        alert.addAction(.init(title: "Okay", style: .default, handler: { _ in
            self.orderEntryViewControllerDelegate?.orderEntryViewControllerDidInitiateLogout(self)
        }))
        present(alert, animated: true, completion: nil)
    }

    func showErrorAlert(_ error: Error) {
        print(error)

        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(.init(title: "Dismiss", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
