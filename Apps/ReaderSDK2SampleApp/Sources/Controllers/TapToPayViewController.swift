//
//  TapToPayViewController.swift
//  R2SampleApp
//
//  Created by Kirstie Booras on 3/23/23.
//  Copyright © 2023 Square, Inc. All rights reserved.
//

import ReaderSDK2
import ReaderSDK2UI
import UIKit

final class TapToPayViewController: UITableViewController {
    private lazy var dataSource = TableViewDataSource(theme: theme, tableView: tableView, sections: makeSections())
    private let theme: Theme
    private let readerManager: ReaderManager
    private let isLinked: Bool

    init(theme: Theme, readerManager: ReaderManager, isLinked: Bool) {
        self.theme = theme
        self.readerManager = readerManager
        self.isLinked = isLinked
        super.init(nibName: nil, bundle: nil)
        title = Strings.Settings.tapToPaySectionTitle
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ColorGenerator.secondaryBackgroundColor(theme: theme)
        tableView.dataSource = dataSource
        tableView.delegate = dataSource
        tableView.rowHeight = UITableView.automaticDimension
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layoutMargins = ReaderSDK2UILayout.preferredMargins(view: view)
        tableView.separatorInset = view.layoutMargins
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorGenerator.statusBarStyle(theme: theme)
    }
}

// MARK: - Helpers
private extension TapToPayViewController {
    func makeSections() -> [Section] {
        let tapToPayRow = Row.button(
            theme: theme,
            title: isLinked ? Strings.Settings.tapToPayRelinkAccountRowTitle : Strings.Settings.tapToPayLinkAccountRowTitle,
            tapHandler: { [weak self] in
                self?.tapToPayLinkButtonPressed()
            }
        )
        return [Section(rows: [tapToPayRow])]
    }

    private func tapToPayLinkButtonPressed() {
        let completionHandler: (Error?) -> Void = { error in
            guard let error = error else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.presentAlert(title: "Error", message: error.localizedDescription)
            }
        }

        if isLinked {
            readerManager.relinkTapToPayReader(completion: completionHandler)
        } else {
            readerManager.linkTapToPayReader(completion: completionHandler)
        }
    }
}
