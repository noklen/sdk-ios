//
//  ChargeDelegate.swift
//  ReaderSDK2-SampleApp
//
//  Created by Mike Silvis on 10/2/19.
//

import Foundation
import ReaderSDK2

protocol ChargeDelegate: AnyObject {
    func charge(_ money: Money)
}
