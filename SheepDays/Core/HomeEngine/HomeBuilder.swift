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
        let pinnedEvents = sortedEvents.filter(\.pinToTop)
        let regularEvents = sortedEvents.filter { !$0.pinToTop }
        let pinnedSection = makePinnedSection(from: pinnedEvents, query: query)
        let regularSections = HomeGrouper.group(regularEvents, query: query).map { group in
            makeSection(from: group, query: query)
        }

        if let pinnedSection {
            return [pinnedSection] + regularSections
        }

        return regularSections
    }
}

private extension HomeBuilder {
    static func makePinnedSection(from events: [Event], query: HomeQuery) -> HomeSection? {
        guard !events.isEmpty else {
            return nil
        }

        return HomeSection(
            id: "pinned",
            title: "置顶",
            items: events.map { event in
                makeDisplayItem(from: event, query: query)
            }
        )
    }

    static func makeSection(from group: HomeEventGroup, query: HomeQuery) -> HomeSection {
        HomeSection(
            id: group.id,
            title: group.title,
            items: group.events.map { event in
                makeDisplayItem(from: event, query: query)
            }
        )
    }

    static func matchesFilters(event: Event, query: HomeQuery, calendar: Calendar = .current) -> Bool {
        guard !event.isArchived else {
            return false
        }

        let normalizedReferenceDate = calendar.startOfDay(for: query.referenceDate)
        let normalizedTargetDate = calendar.startOfDay(for: event.targetDate)

        guard matchesScope(
            event: event,
            normalizedTargetDate: normalizedTargetDate,
            normalizedReferenceDate: normalizedReferenceDate,
            query: query
        ) else {
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
        case .none:
            return false
        case .untaggedOnly:
            guard event.tags.isEmpty else {
                return false
            }
        }

        return query.timeRangeFilter.contains(
            normalizedTargetDate,
            referenceDate: normalizedReferenceDate,
            calendar: calendar,
            scope: query.scope
        )
    }

    static func matchesScope(
        event: Event,
        normalizedTargetDate: Date,
        normalizedReferenceDate: Date,
        query: HomeQuery
    ) -> Bool {
        switch query.scope {
        case .homeUpcoming:
            guard query.includeAllEvents || event.showOnHome else {
                return false
            }

            return normalizedTargetDate >= normalizedReferenceDate

        case .memorialPast:
            guard event.isMemorial else {
                return false
            }

            return normalizedTargetDate <= normalizedReferenceDate
        }
    }

    static func makeDisplayItem(from event: Event, query: HomeQuery) -> HomeDisplayItem {
        let dateDisplay = HomeDateDisplayContent(referenceDate: event.targetDate, today: query.referenceDate)

        return HomeDisplayItem(
            id: event.id,
            sourceEventId: event.id,
            title: event.title,
            iconSystemName: event.iconSystemName,
            tintHex: event.notebook?.colorHex,
            badgeText: badgeText(from: dateDisplay, query: query),
            isToday: dateDisplay.dayOffsetFromToday == 0,
            stateIndicators: makeStateIndicators(from: event),
            sortKey: Double(dateDisplay.dayOffsetFromToday),
            groupKey: nil
        )
    }

    static func badgeText(from dateDisplay: HomeDateDisplayContent, query: HomeQuery) -> String {
        switch query.scope {
        case .homeUpcoming:
            return dateDisplay.badgeText
        case .memorialPast:
            let elapsedDays = abs(dateDisplay.dayOffsetFromToday)
            return elapsedDays == 0 ? dateDisplay.badgeText : "+\(elapsedDays)"
        }
    }

    static func makeStateIndicators(from event: Event) -> Set<HomeDisplayItemStateIndicator> {
        var indicators: Set<HomeDisplayItemStateIndicator> = []

        if event.hasChecklistItems {
            indicators.insert(.checklist)
        }

        if !event.reminderPresets.isEmpty {
            indicators.insert(.reminder)
        }

        if event.showOnHome {
            indicators.insert(.showOnHome)
        }

        if event.pinToTop {
            indicators.insert(.pinned)
        }

        return indicators
    }
}
