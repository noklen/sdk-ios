//
//  ConfigExtensions.swift
//  ReaderSDK2
//
//  Created by Mike Silvis on 3/11/20.
//  Copyright © 2020 Square, Inc. All rights reserved.
//

import ReaderSDK2

extension Config {
    /// In this sample app, `localSalesID` serves as a unique, hypothetical identifier for a transaction within the business logic of your application.
    /// It's utilized here to demonstrate how one might manage idempotency. In your actual application, the structure and logic for your business logic ID may vary.
    /// The use of an idempotency key, alongside a custom ID like this, ensures that even if a transaction is retried, it will not be duplicated.
    /// If a transaction fails and needs to be retried with the same ID, a new idempotency key is generated, thereby maintaining the integrity of the transaction and preventing inadvertent duplication.
    static var localSalesID: String = String(UUID().uuidString.prefix(8))

    /// Defines the default parameters with which a payment attempt is initiated. The idempotency key included here serves as a placeholder,
    /// and it will be substituted with an idempotency key that is specifically tied to your unique business-logic ID. See `OrderEntryViewController`.
    static var parameters = PaymentParameters(
        idempotencyKey: UUID().uuidString,
        amountMoney: Money(amount: 0, currency: .USD)
    )

    static var storeSwipedCard: Bool = false

    enum CardOnFile {
        static var cardID: String? {
            get {
                return UserDefaults.standard.string(forKey: "ReaderSDK-Sample-CardOnFile-CardID")
            }
            set {
                UserDefaults.standard.set(newValue, forKey: "ReaderSDK-Sample-CardOnFile-CardID")
            }
        }
    }

    enum HouseAccount {
        static var paymentSourceId: String? {
            get {
                return UserDefaults.standard.string(forKey: "ReaderSDK-Sample-HouseAccount-PaymentSourceToken")
            }
            set {
                UserDefaults.standard.set(newValue, forKey: "ReaderSDK-Sample-HouseAccount-PaymentSourceToken")
            }
        }
    }

    public static var theme: Theme {
        get {
            var option: Theme.Option {
                guard let rawValue = UserDefaults.standard.string(forKey: "ReaderSDK-Sample-Theme") else {
                    return Theme.Option.standard
                }

                return Theme.Option(rawValue: rawValue) ?? Theme.Option.standard
            }

            return option.theme
        }
        set {
            var option: Theme.Option {
                let updatedTheme = Theme.Option.allCases.first { option -> Bool in
                    return option.theme == newValue
                }

                return updatedTheme ?? Theme.Option.standard
            }

            UserDefaults.standard.set(option.rawValue, forKey: "ReaderSDK-Sample-Theme")
        }
    }
}
