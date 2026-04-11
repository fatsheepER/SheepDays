//
//  HomeSorter.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import Foundation

enum HomeSorter {
    static func sort(_ events: [Event], mode: HomeSortMode) -> [Event] {
        events.sorted { lhs, rhs in
            if let primaryComparison = comparePrimary(lhs: lhs, rhs: rhs, mode: mode) {
                return primaryComparison
            }

            return compareStableFallback(lhs: lhs, rhs: rhs)
        }
    }
}

private extension HomeSorter {
    static func comparePrimary(lhs: Event, rhs: Event, mode: HomeSortMode) -> Bool? {
        switch mode {
        case .importanceDescending:
            return compare(lhs.importanceLevel, rhs.importanceLevel, ascending: false)
        case .importanceAscending:
            return compare(lhs.importanceLevel, rhs.importanceLevel, ascending: true)
        case .targetDateDescending:
            return compare(lhs.targetDate, rhs.targetDate, ascending: false)
        case .targetDateAscending:
            return compare(lhs.targetDate, rhs.targetDate, ascending: true)
        case .createdAtDescending:
            return compare(lhs.createdAt, rhs.createdAt, ascending: false)
        case .createdAtAscending:
            return compare(lhs.createdAt, rhs.createdAt, ascending: true)
        case .updatedAtDescending:
            return compare(lhs.updatedAt, rhs.updatedAt, ascending: false)
        case .updatedAtAscending:
            return compare(lhs.updatedAt, rhs.updatedAt, ascending: true)
        }
    }

    static func compareStableFallback(lhs: Event, rhs: Event) -> Bool {
        if lhs.targetDate != rhs.targetDate {
            return lhs.targetDate < rhs.targetDate
        }

        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        }

        let titleComparison = lhs.title.localizedCompare(rhs.title)
        if titleComparison != .orderedSame {
            return titleComparison == .orderedAscending
        }

        return lhs.id.uuidString < rhs.id.uuidString
    }

    static func compare<T: Comparable>(_ lhs: T, _ rhs: T, ascending: Bool) -> Bool? {
        guard lhs != rhs else {
            return nil
        }

        return ascending ? lhs < rhs : lhs > rhs
    }
}
