//
//  HomeBuilder.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import Foundation

enum HomeBuilder {
    static func build(events: [Event], query: HomeQuery) -> [HomeSection] {
        let filteredEvents = events.filter { event in
            matchesFilters(event: event, query: query)
        }
        let sortedEvents = HomeSorter.sort(filteredEvents, mode: query.sortingMode)
        let groups = HomeGrouper.group(sortedEvents, query: query)

        return groups.map { group in
            HomeSection(
                id: group.id,
                title: group.title,
                items: group.events.map { event in
                    makeDisplayItem(from: event, query: query)
                }
            )
        }
    }
}

private extension HomeBuilder {
    static func matchesFilters(event: Event, query: HomeQuery, calendar: Calendar = .current) -> Bool {
        guard !event.isArchived else {
            return false
        }

        guard query.includeAllEvents || event.showOnHome else {
            return false
        }

        let normalizedReferenceDate = calendar.startOfDay(for: query.referenceDate)
        let normalizedTargetDate = calendar.startOfDay(for: event.targetDate)

        guard normalizedTargetDate >= normalizedReferenceDate else {
            return false
        }

        switch query.notebookSourceFilter {
        case .all:
            break
        case let .selected(ids):
            guard let notebookId = event.notebook?.id,
                  ids.contains(notebookId) else {
                return false
            }
        case .none:
            return false
        }

        switch query.tagSourceFilter {
        case .all:
            break
        case let .selected(ids):
            if event.tags.isEmpty {
                break
            }

            let tagIDs = Set(event.tags.map(\.id))
            guard tagIDs.isSubset(of: ids) else {
                return false
            }
        case .untaggedOnly:
            guard event.tags.isEmpty else {
                return false
            }
        }

        guard let upperBound = query.timeRangeFilter.upperBound(from: normalizedReferenceDate, calendar: calendar) else {
            return true
        }

        return normalizedTargetDate <= upperBound
    }

    static func makeDisplayItem(from event: Event, query: HomeQuery) -> HomeDisplayItem {
        let dateDisplay = HomeDateDisplayContent(referenceDate: event.targetDate, today: query.referenceDate)

        return HomeDisplayItem(
            id: event.id,
            sourceEventId: event.id,
            title: event.title,
            iconSystemName: event.iconSystemName,
            tintHex: event.notebook?.colorHex,
            badgeText: dateDisplay.badgeText,
            isToday: dateDisplay.dayOffsetFromToday == 0,
            sortKey: Double(dateDisplay.dayOffsetFromToday),
            groupKey: nil
        )
    }
}
