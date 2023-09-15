//
//  ThemeExtensions.swift
//  ReaderSDK2
//
//  Created by Tobi Schweiger on 8/8/23.
//  Copyright © 2023 Square, Inc. All rights reserved.
//

import ReaderSDK2

extension Theme {
    enum Option: String, CustomStringConvertible, CaseIterable, Equatable {
        case standard = "Standard"
        case burger = "Burger"
        case basketball = "Basketball"

        var description: String {
            return rawValue
        }

        var theme: Theme {
            switch self {
            case .standard:
                return Theme()
            case .burger:
                return Theme(
                    titleColor: .white,
                    titleFont: .systemFont(ofSize: 24, weight: .black),
                    subtitleColor: .white,
                    subtitleFont: .systemFont(ofSize: 16, weight: .medium),
                    tintColor: #colorLiteral(red: 0.3843137255, green: 0.6745098039, blue: 0.2078431373, alpha: 1),
                    backgroundColor: .black,
                    buttonTextColor: .white,
                    buttonFont: .systemFont(ofSize: 32, weight: .black),
                    buttonCornerRadius: 8,
                    informationIconColor: #colorLiteral(red: 0.3843137255, green: 0.6745098039, blue: 0.2078431373, alpha: 1),
                    successIconColor: #colorLiteral(red: 0.3843137255, green: 0.6745098039, blue: 0.2078431373, alpha: 1),
                    errorIconColor: #colorLiteral(red: 0.8431372549, green: 0.1803921569, blue: 0.1960784314, alpha: 1),
                    cornerRadius: 0,
                    presentationStyle: .alwaysFullscreen,
                    inputFieldColor: .black,
                    inputFieldTextColor: .white,
                    inputFieldPlaceholderTextColor: .white,
                    inputFieldErrorColor: #colorLiteral(red: 0.8431372549, green: 0.1803921569, blue: 0.1960784314, alpha: 1)
                )
            case .basketball:
                return Theme(
                    titleColor: .white,
                    titleFont: .systemFont(ofSize: 24, weight: .black),
                    subtitleColor: .white,
                    subtitleFont: .systemFont(ofSize: 16, weight: .medium),
                    tintColor: #colorLiteral(red: 1, green: 0.7788988948, blue: 0.1741508245, alpha: 1),
                    backgroundColor: #colorLiteral(red: 0.1154184118, green: 0.2600637376, blue: 0.5409679413, alpha: 1),
                    buttonTextColor: .white,
                    buttonFont: .systemFont(ofSize: 32, weight: .black),
                    buttonCornerRadius: 8,
                    informationIconColor: .white,
                    successIconColor: #colorLiteral(red: 1, green: 0.7788988948, blue: 0.1741508245, alpha: 1),
                    errorIconColor: #colorLiteral(red: 1, green: 0.7788988948, blue: 0.1741508245, alpha: 1),
                    cornerRadius: 0,
                    presentationStyle: .alwaysFullscreen,
                    inputFieldColor: #colorLiteral(red: 0.1154184118, green: 0.2600637376, blue: 0.5409679413, alpha: 1),
                    inputFieldTextColor: .white,
                    inputFieldPlaceholderTextColor: .white,
                    inputFieldErrorColor: #colorLiteral(red: 1, green: 0.7788988948, blue: 0.1741508245, alpha: 1)
                )
            }
        }
    }
}
