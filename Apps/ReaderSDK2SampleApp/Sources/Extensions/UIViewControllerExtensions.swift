//
//  UIViewControllerExtensions.swift
//  R2SampleApp
//
//  Created by Vivek Vichare on 10/3/21.
//  Copyright © 2021 Square, Inc. All rights reserved.
//

import UIKit

// MARK: - UIViewController add-ons for the sample app.
extension UIViewController {
    func isUsingCompactLayout() -> Bool {
        return traitCollection.horizontalSizeClass == .compact
    }

    func presentAlert(title: String, message: String, onDismiss: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: Strings.Settings.dismissAlertTitle, style: .default, handler: onDismiss))

        self.present(alert, animated: true)
    }
}
