//
//  HomeFocusState.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/11.
//

import Foundation

enum HomeNotebookSourceFilter: Equatable {
    case all
    case selected(Set<UUID>)
    case none

    var isDefault: Bool {
        self == .all
    }

    func includes(id: UUID) -> Bool {
        switch self {
        case .all:
            return true
        case let .selected(ids):
            return ids.contains(id)
        case .none:
            return false
        }
    }

    func toggleSingle(id: UUID, allIDs: Set<UUID>) -> HomeNotebookSourceFilter {
        switch self {
        case .all:
            let remaining = allIDs.subtracting([id])
            return normalizedSelection(remaining, allIDs: allIDs)
        case let .selected(ids):
            if ids.contains(id) {
                let remaining = ids.subtracting([id])
                return normalizedSelection(remaining, allIDs: allIDs)
            }

            return normalizedSelection(ids.union([id]), allIDs: allIDs)
        case .none:
            return normalizedSelection([id], allIDs: allIDs)
        }
    }

    func toggleBulk(allIDs: Set<UUID>) -> HomeNotebookSourceFilter {
        guard !allIDs.isEmpty else {
            return self
        }

        switch self {
        case .all:
            return .none
        case .selected, .none:
            return normalizedSelection(allIDs, allIDs: allIDs)
        }
    }

    private func normalizedSelection(_ ids: Set<UUID>, allIDs: Set<UUID>) -> HomeNotebookSourceFilter {
        if ids.isEmpty {
            return .none
        }

        if ids == allIDs {
            return .all
        }

        return .selected(ids)
    }
}

enum HomeTagSourceFilter: Equatable {
    case all
    case selected(Set<UUID>)
    case untaggedOnly

    var isDefault: Bool {
        self == .all
    }

    func includes(id: UUID) -> Bool {
        switch self {
        case .all:
            return true
        case let .selected(ids):
            return ids.contains(id)
        case .untaggedOnly:
            return false
        }
    }

    func toggleSingle(id: UUID, allIDs: Set<UUID>) -> HomeTagSourceFilter {
        switch self {
        case .all:
            let remaining = allIDs.subtracting([id])
            return normalizedSelection(remaining, allIDs: allIDs)
        case let .selected(ids):
            if ids.contains(id) {
                let remaining = ids.subtracting([id])
                return normalizedSelection(remaining, allIDs: allIDs)
            }

            return normalizedSelection(ids.union([id]), allIDs: allIDs)
        case .untaggedOnly:
            return normalizedSelection([id], allIDs: allIDs)
        }
    }

    func toggleBulk(allIDs: Set<UUID>) -> HomeTagSourceFilter {
        guard !allIDs.isEmpty else {
            return self
        }

        switch self {
        case .all:
            return .untaggedOnly
        case .selected, .untaggedOnly:
            return normalizedSelection(allIDs, allIDs: allIDs)
        }
    }

    private func normalizedSelection(_ ids: Set<UUID>, allIDs: Set<UUID>) -> HomeTagSourceFilter {
        if ids.isEmpty {
            return .untaggedOnly
        }

        if ids == allIDs {
            return .all
        }

        return .selected(ids)
    }
}

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
    var notebookSourceFilter: HomeNotebookSourceFilter = .all
    var tagSourceFilter: HomeTagSourceFilter = .all
    var timeRange: HomeFocusTimeRange = .all
    var sortMode: HomeSortMode = .targetDateAscending
    var groupingMode: HomeGroupingMode = .none
}
