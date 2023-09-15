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
    private let idempotencyKeyStorage: IdempotencyKeyStorage<String>
    private let paymentManager: PaymentManager
    private lazy var keypadViewController = KeypadViewController(theme: theme, money: money, chargeDelegate: self)
    private weak var orderEntryViewControllerDelegate: OrderEntryViewControllerDelegate?

    init(
        theme: Theme,
        authorizationManager: AuthorizationManager,
        idempotencyKeyStorage: IdempotencyKeyStorage<String>,
        paymentManager: PaymentManager,
        delegate: OrderEntryViewControllerDelegate
    ) {
        self.theme = theme
        self.authorizationManager = authorizationManager
        self.idempotencyKeyStorage = idempotencyKeyStorage
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
        let parameters = PaymentParameters(from: Config.parameters)

        /// Retrieves an idempotency key associated with the current sales ID from storage. If no existing key is found,
        /// a new UUID is generated and stored as the idempotency key for that sales ID. The retrieved or newly generated
        /// idempotency key is then assigned to the payment parameters, ensuring that the transaction maintains its uniqueness,
        /// even if it needs to be retried.
        let idempotencyKey = idempotencyKeyStorage.get(id: Config.localSalesID) ?? {
            let newKey = UUID().uuidString
            idempotencyKeyStorage.store(id: Config.localSalesID, idempotencyKey: newKey)
            return newKey
        }()
        parameters.idempotencyKey = idempotencyKey
        parameters.amountMoney = money

        let paymentViewController = PaymentViewController(
            parameters: parameters,
            paymentManager: paymentManager,
            theme: theme,
            delegate: self
        )
        paymentViewController.cardID = Config.CardOnFile.cardID
        paymentViewController.houseAccountPaymentSourceId = Config.HouseAccount.paymentSourceId

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

        // Upon completion of the order, generate a new custom ID (serving as your unique business-logic ID),
        // so that subsequent transactions are assigned a distinct idempotency key. The sale or order is considered
        // finalized at this stage.
        //
        // In a production application, this ID would usually be set when obtaining a unique identifier
        // for the transaction from your backend or generating it locally, prior to calling the
        // `startPayment` method.
        Config.localSalesID = String(UUID().uuidString.prefix(8))
        Config.parameters.amountMoney = Money(amount: 0, currency: .USD)

        // Show transaction complete
        let transactionComplete = TransactionCompleteViewController(theme: theme, payment: payment)
        presentingNavigationConroller.setViewControllers([transactionComplete], animated: true)
    }

    func paymentManager(_ paymentManager: PaymentManager, didFail payment: Payment, withError error: Error) {
        switch (error as NSError).code {
        case PaymentError.paymentAlreadyInProgress.rawValue:
            // Do not dismiss the current view controller since the current payment is using the view controller, however log the error
            print(error)
        case PaymentError.notAuthorized.rawValue:
            dismiss(animated: true, completion: self.showLogoutAlert)
        case PaymentError.timedOut.rawValue:
            dismiss(animated: true, completion: nil)
        case PaymentError.idempotencyKeyReused.rawValue:
            self.showErrorAlert(message: "Developer error: Idempotency key reused. Check the most recent payments to see their status.")

            // The idempotency key has been utilized at this point, yet the transaction was unsuccessful.
            // It is essential to delete the idempotency key associated with this sale, allowing
            // a new key to be generated if the transaction is retried using the same sales ID.
            idempotencyKeyStorage.delete(id: Config.localSalesID)

            dismiss(animated: true, completion: nil)
        default:
            // Same as the case above, we need to ensure that this sale is no longer associated with this
            // idempotency key since it has been used, and a new key will be generated when the payment is restarted.
            idempotencyKeyStorage.delete(id: Config.localSalesID)

            dismiss(animated: true) { self.showErrorAlert(error) }
        }
    }

    func paymentManager(_ paymentManager: PaymentManager, didCancel payment: Payment) {
        // The idempotency key has presumably been utilized at this point, yet the transaction was cancelled.
        // It is essential to delete the idempotency key associated with this sale, allowing
        // a new key to be generated if the transaction is retried using the same custom ID.
        idempotencyKeyStorage.delete(id: Config.localSalesID)
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
        showErrorAlert(message: error.localizedDescription)
    }

    func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "Dismiss", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
