//
//  HomeBuilder.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import Foundation

enum HomeBuilder {
    static func build(events: [Event], query: HomeQuery) -> [HomeSection] {
        let items = events
            .filter { !$0.isArchived }
            .compactMap { makeDisplayItem(from: $0, query: query) }
            .sorted { lhs, rhs in
                if lhs.sortKey != rhs.sortKey {
                    return lhs.sortKey < rhs.sortKey
                }

                return lhs.title.localizedCompare(rhs.title) == .orderedAscending
            }

        return [
            HomeSection(
                id: "all",
                title: "Events",
                items: items
            )
        ]
    }
}

private extension HomeBuilder {
    static func makeDisplayItem(from event: Event, query: HomeQuery) -> HomeDisplayItem? {
        if !query.includeAllEvents && !event.showOnHome {
            return nil
        }

        if !query.includedNotebookIDs.isEmpty,
           let notebookId = event.notebook?.id,
           !query.includedNotebookIDs.contains(notebookId) {
            return nil
        }

        let dateDisplay = HomeDateDisplayContent(referenceDate: event.targetDate, today: query.referenceDate)
        if dateDisplay.dayOffsetFromToday < 0 {
            return nil
        }

        return HomeDisplayItem(
            id: event.id,
            sourceEventId: event.id,
            title: event.title,
            iconSystemName: event.iconSystemName,
            badgeText: dateDisplay.badgeText,
            isToday: dateDisplay.dayOffsetFromToday == 0,
            sortKey: Double(dateDisplay.dayOffsetFromToday),
            groupKey: nil
        )
    }
}
