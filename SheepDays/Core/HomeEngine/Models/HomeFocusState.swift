//
//  HomeFocusState.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/11.
//

import Foundation

enum HomeFocusTimeRange: CaseIterable, Equatable {
    case sevenDays
    case oneMonth
    case sixMonths
    case all

    var title: String {
        switch self {
        case .sevenDays:
            return "7 天内"
        case .oneMonth:
            return "1 个月内"
        case .sixMonths:
            return "半年内"
        case .all:
            return "全部"
        }
    }
}

enum HomeSortMode: CaseIterable, Equatable {
    case importanceDescending
    case importanceAscending
    case targetDateDescending
    case targetDateAscending
    case createdAtDescending
    case createdAtAscending
    case updatedAtDescending
    case updatedAtAscending

    var title: String {
        switch self {
        case .importanceDescending:
            return "重要程度降序"
        case .importanceAscending:
            return "重要程度升序"
        case .targetDateDescending:
            return "日期降序"
        case .targetDateAscending:
            return "日期升序"
        case .createdAtDescending:
            return "创建时间降序"
        case .createdAtAscending:
            return "创建时间升序"
        case .updatedAtDescending:
            return "编辑时间降序"
        case .updatedAtAscending:
            return "编辑时间升序"
        }
    }
}

enum HomeGroupingMode: CaseIterable, Equatable {
    case none
    case notebook
    case timeRange
    case importance

    var title: String {
        switch self {
        case .none:
            return "不分组"
        case .notebook:
            return "按事件本分组"
        case .timeRange:
            return "按时间范围分组"
        case .importance:
            return "按重要程度分组"
        }
    }
}

struct HomeFocusState: Equatable {
    var selectedNotebookIDs: Set<UUID> = []
    var selectedTagIDs: Set<UUID> = []
    var timeRange: HomeFocusTimeRange = .all
    var sortMode: HomeSortMode = .targetDateAscending
    var groupingMode: HomeGroupingMode = .none
}
