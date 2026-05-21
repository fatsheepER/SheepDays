//
//  FocusSortField.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/5/21.
//

import SwiftUI

enum FocusSortField: CaseIterable {
    case importance
    case targetDate
    case createdAt
    case updatedAt

    var title: String {
        switch self {
        case .importance:
            return "按重要程度"
        case .targetDate:
            return "按日期"
        case .createdAt:
            return "按创建时间"
        case .updatedAt:
            return "按编辑时间"
        }
    }

    static var longestTitle: String {
        allCases
            .map(\.title)
            .max(by: { $0.count < $1.count }) ?? ""
    }
}
