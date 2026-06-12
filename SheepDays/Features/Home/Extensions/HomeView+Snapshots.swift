//
//  HomeView+Snapshots.swift
//  SheepDays
//
//  Created by Codex on 2026/6/12.
//

import Foundation
import SwiftData

extension HomeView {
    func loadHomeSnapshot() -> (sections: [HomeSection], targetDatesByEventID: [UUID: Date]) {
        do {
            let events = try modelContext.fetch(FetchDescriptor<Event>())
            let query = HomeQuery(
                scope: .homeUpcoming,
                referenceDate: referenceDate,
                notebookSourceFilter: homeFocusState.notebookSourceFilter,
                tagSourceFilter: homeFocusState.tagSourceFilter,
                timeRangeFilter: homeFocusState.timeRange,
                groupingMode: homeFocusState.groupingMode,
                sortingMode: homeFocusState.sortMode,
                includeAllEvents: false
            )

            let sections = HomeBuilder.build(events: events, query: query)
                .filter { !$0.items.isEmpty }
            let targetDatesByEventID = Dictionary(
                uniqueKeysWithValues: events.map { ($0.id, $0.targetDate) }
            )

            return (sections, targetDatesByEventID)
        } catch {
            return ([], [:])
        }
    }

    func loadMemorialSnapshot() -> (sections: [HomeSection], targetDatesByEventID: [UUID: Date]) {
        do {
            let events = try modelContext.fetch(FetchDescriptor<Event>())
            let query = HomeQuery(
                scope: .memorialPast,
                referenceDate: referenceDate,
                notebookSourceFilter: memorialFocusState.notebookSourceFilter,
                tagSourceFilter: memorialFocusState.tagSourceFilter,
                timeRangeFilter: memorialFocusState.timeRange,
                groupingMode: memorialFocusState.groupingMode,
                sortingMode: memorialFocusState.sortMode,
                includeAllEvents: true
            )

            let sections = HomeBuilder.build(events: events, query: query)
                .filter { !$0.items.isEmpty }
            let targetDatesByEventID = Dictionary(
                uniqueKeysWithValues: events.map { ($0.id, $0.targetDate) }
            )

            return (sections, targetDatesByEventID)
        } catch {
            return ([], [:])
        }
    }
}
