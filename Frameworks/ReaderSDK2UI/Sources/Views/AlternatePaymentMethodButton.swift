//
//  AlternatePaymentMethodButton.swift
//  ReaderSDK2UI
//
//  Created by Mike Silvis on 11/5/21.
//  Copyright © 2021 Square, Inc. All rights reserved.
//

import ReaderSDK2
import UIKit

final class AlternatePaymentButton: UIButton {
    private var method: AlternatePaymentMethod?
    private var didTap: ((AlternatePaymentMethod) -> Void)?

    convenience init(method: AlternatePaymentMethod, didTap: @escaping (AlternatePaymentMethod) -> Void) {
        self.init(type: .system)

        self.method = method
        self.didTap = didTap

        self.translatesAutoresizingMaskIntoConstraints = false

        addTarget(self, action: #selector(didTouchUpInside), for: .touchUpInside)
    }

    @objc func didTouchUpInside() {
        didTap!(method!)
    }
}
