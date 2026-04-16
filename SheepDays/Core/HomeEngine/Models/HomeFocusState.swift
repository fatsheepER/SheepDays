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
            return "7天内"
        case .oneMonth:
            return "1个月内"
        case .sixMonths:
            return "半年内"
        case .all:
            return "全部"
        }
    }

    func upperBound(from referenceDate: Date, calendar: Calendar) -> Date? {
        switch self {
        case .sevenDays:
            return calendar.date(byAdding: .day, value: 7, to: referenceDate)
        case .oneMonth:
            return calendar.date(byAdding: .month, value: 1, to: referenceDate)
        case .sixMonths:
            return calendar.date(byAdding: .month, value: 6, to: referenceDate)
        case .all:
            return nil
        }
    }
}

enum HomeTimeRangeBucket: String, CaseIterable {
    case sevenDays
    case oneMonth
    case sixMonths
    case furtherAway

    var title: String {
        switch self {
        case .sevenDays:
            return "7天内"
        case .oneMonth:
            return "1个月内"
        case .sixMonths:
            return "半年内"
        case .furtherAway:
            return "更远"
        }
    }

    static func availableBuckets(for timeRange: HomeFocusTimeRange) -> [HomeTimeRangeBucket] {
        switch timeRange {
        case .sevenDays:
            return [.sevenDays]
        case .oneMonth:
            return [.sevenDays, .oneMonth]
        case .sixMonths:
            return [.sevenDays, .oneMonth, .sixMonths]
        case .all:
            return [.sevenDays, .oneMonth, .sixMonths, .furtherAway]
        }
    }

    func contains(_ date: Date, referenceDate: Date, calendar: Calendar) -> Bool {
        let normalizedReferenceDate = calendar.startOfDay(for: referenceDate)
        let normalizedDate = calendar.startOfDay(for: date)

        switch self {
        case .sevenDays:
            guard let upperBound = calendar.date(byAdding: .day, value: 7, to: normalizedReferenceDate) else {
                return false
            }

            return normalizedDate >= normalizedReferenceDate && normalizedDate <= upperBound
        case .oneMonth:
            guard let sevenDayUpperBound = calendar.date(byAdding: .day, value: 7, to: normalizedReferenceDate),
                  let monthUpperBound = calendar.date(byAdding: .month, value: 1, to: normalizedReferenceDate) else {
                return false
            }

            return normalizedDate > sevenDayUpperBound && normalizedDate <= monthUpperBound
        case .sixMonths:
            guard let monthUpperBound = calendar.date(byAdding: .month, value: 1, to: normalizedReferenceDate),
                  let sixMonthUpperBound = calendar.date(byAdding: .month, value: 6, to: normalizedReferenceDate) else {
                return false
            }

            return normalizedDate > monthUpperBound && normalizedDate <= sixMonthUpperBound
        case .furtherAway:
            guard let sixMonthUpperBound = calendar.date(byAdding: .month, value: 6, to: normalizedReferenceDate) else {
                return false
            }

            return normalizedDate > sixMonthUpperBound
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
