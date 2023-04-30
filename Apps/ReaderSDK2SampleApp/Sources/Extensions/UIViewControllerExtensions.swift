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
}
