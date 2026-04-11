//
//  HomeGrouper.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import Foundation

enum HomeGrouper {
    static func group(
        _ events: [Event],
        query: HomeQuery,
        calendar: Calendar = .current
    ) -> [HomeEventGroup] {
        switch query.groupingMode {
        case .none:
            return [
                HomeEventGroup(
                    id: "all",
                    title: "Events",
                    events: events
                )
            ]
        case .notebook:
            return groupByNotebook(events)
        case .timeRange:
            return groupByTimeRange(events, query: query, calendar: calendar)
        case .importance:
            return groupByImportance(events)
        }
    }
}

struct HomeEventGroup {
    let id: String
    let title: String
    let events: [Event]
}

private extension HomeGrouper {
    static func groupByNotebook(_ events: [Event]) -> [HomeEventGroup] {
        let grouped = Dictionary(grouping: events) { event in
            event.notebook?.id.uuidString ?? "uncategorized"
        }

        return grouped
            .map { key, events in
                let title = events.first?.notebook?.name ?? "未分类"
                return HomeEventGroup(id: "notebook:\(key)", title: title, events: events)
            }
            .sorted { lhs, rhs in
                lhs.title.localizedCompare(rhs.title) == .orderedAscending
            }
    }

    static func groupByTimeRange(
        _ events: [Event],
        query: HomeQuery,
        calendar: Calendar
    ) -> [HomeEventGroup] {
        let buckets = HomeTimeRangeBucket.availableBuckets(for: query.timeRange)

        return buckets.compactMap { bucket in
            let bucketEvents = events.filter { event in
                bucket.contains(event.targetDate, referenceDate: query.referenceDate, calendar: calendar)
            }

            guard !bucketEvents.isEmpty else {
                return nil
            }

            return HomeEventGroup(
                id: "time:\(bucket.rawValue)",
                title: bucket.title,
                events: bucketEvents
            )
        }
    }

    static func groupByImportance(_ events: [Event]) -> [HomeEventGroup] {
        let levels = stride(from: 5, through: 0, by: -1)

        return levels.compactMap { level in
            let levelEvents = events.filter { $0.importanceLevel == level }

            guard !levelEvents.isEmpty else {
                return nil
            }

            return HomeEventGroup(
                id: "importance:\(level)",
                title: "\(level)/5",
                events: levelEvents
            )
        }
    }
}

private enum HomeTimeRangeBucket: String, CaseIterable {
    case sevenDays
    case oneMonth
    case sixMonths
    case furtherAway

    var title: String {
        switch self {
        case .sevenDays:
            return "7 天内"
        case .oneMonth:
            return "1 个月内"
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
