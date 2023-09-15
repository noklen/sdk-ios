//
//  PaymentParametersExtension.swift
//  R2SampleApp
//
//  Created by Tobi Schweiger on 8/10/23.
//  Copyright © 2023 Square, Inc. All rights reserved.
//

import ReaderSDK2

extension PaymentParameters {
    convenience init(from parameters: PaymentParameters) {
        self.init(
            idempotencyKey: parameters.idempotencyKey,
            amountMoney: parameters.amountMoney
        )
        self.acceptPartialAuthorization = parameters.acceptPartialAuthorization
        self.autocomplete = parameters.autocomplete
        self.delayDuration = parameters.delayDuration
        self.tipMoney = parameters.tipMoney
        self.appFeeMoney = parameters.appFeeMoney
        self.locationId = parameters.locationId
        self.orderID = parameters.orderID
        self.referenceID = parameters.referenceID
        self.customerID = parameters.customerID
        self.employeeId = parameters.employeeId
        self.note = parameters.note
        self.statementDescriptionIdentifier = parameters.statementDescriptionIdentifier
        self.cardHandle = parameters.cardHandle
    }
}
