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
        let buckets = HomeTimeRangeBucket.availableBuckets(for: query.timeRangeFilter)

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
