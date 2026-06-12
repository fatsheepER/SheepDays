//
//  EventChecklistLayoutTypes.swift
//  SheepDays
//
//  Created by Codex on 2026/6/12.
//

import Foundation

enum ChecklistScrollTarget: Hashable {
    case newItem
    case item(UUID)
}

enum ChecklistRowMode: Equatable {
    case normal
    case floating
}

enum ChecklistCoordinateSpace {
    static let name = "event-detail-checklist"
}
