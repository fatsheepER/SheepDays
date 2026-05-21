//
//  FocusSortDirection.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/5/21.
//

import SwiftUI

enum FocusSortDirection: CaseIterable {
    case descending
    case ascending

    var title: String {
        switch self {
        case .descending:
            return "降序"
        case .ascending:
            return "升序"
        }
    }

    static var longestTitle: String {
        allCases
            .map(\.title)
            .max(by: { $0.count < $1.count }) ?? ""
    }
}
