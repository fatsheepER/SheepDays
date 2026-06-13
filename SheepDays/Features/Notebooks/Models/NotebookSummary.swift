//
//  NotebookSummary.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/9.
//

import SwiftUI

struct NotebookSummary: Identifiable {
    let notebook: Notebook
    let events: [Event]
    let futureEventCount: Int
    let pastEventCount: Int
    let weekEvents: [Event]
    let nextEvent: Event?
    let eventDays: Set<Date>
    let today: Date

    var id: UUID {
        notebook.id
    }

    var activeEventCount: Int {
        events.count
    }

    var additionalWeekEventCount: Int {
        guard nextEvent != nil else {
            return 0
        }

        return max(0, weekEvents.count - 1)
    }
}
