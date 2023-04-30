//
//  PriceUpdateDelegate.swift
//  R2SampleApp
//
//  Created by Vivek Vichare on 9/28/21.
//  Copyright © 2021 Square, Inc. All rights reserved.
//

import ReaderSDK2

protocol PriceUpdateDelegate: AnyObject {
    func didUpdate(money: Money)
}
