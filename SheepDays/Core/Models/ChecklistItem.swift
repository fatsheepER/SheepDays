//
//  ChecklistItem.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import Foundation
import SwiftData

@Model
final class ChecklistItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var isCompleted: Bool
    var sortIndex: Int
    var createdAt: Date
    var updatedAt: Date

    var event: Event?

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        sortIndex: Int,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        event: Event? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.sortIndex = sortIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.event = event
    }
}
