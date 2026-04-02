//
//  Event.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import Foundation
import SwiftUI
import SwiftData

enum EventReminderPreset: String, Codable, CaseIterable {
    case atEventTime
    case oneMonthBefore
    case halfMonthBefore
    case oneWeekBefore
    case threeDaysBefore
    case oneDayBefore
}

@Model
final class Event {
    @Attribute(.unique) var id: UUID
    var title: String
    var note: String?

    var targetDate: Date
    var allDay: Bool
    var isMemorial: Bool

    var iconSystemName: String?
    var tintHex: String?
    var importanceLevel: Int
    var showOnHome: Bool
    var pinToTop: Bool

    var isArchived: Bool
    var archivedAt: Date?

    // Store raw values to keep the model persistence-friendly while exposing a typed API.
    var reminderPresetRawValues: [String]
    var allDayReminderHour: Int
    var allDayReminderMinute: Int

    var createdAt: Date
    var updatedAt: Date

    @Relationship(inverse: \Notebook.events) var notebook: Notebook?
    @Relationship(inverse: \Tag.events) var tags: [Tag]

    var reminderPresets: [EventReminderPreset] {
        get {
            reminderPresetRawValues.compactMap(EventReminderPreset.init(rawValue:))
        }
        set {
            reminderPresetRawValues = newValue.map(\.rawValue)
        }
    }

    init(
        title: String,
        targetDate: Date,
        allDay: Bool = true,
        notebook: Notebook? = nil
    ) {
        let now = Date()
        self.id = UUID()
        self.title = title
        self.note = nil
        self.targetDate = targetDate
        self.allDay = allDay
        self.isMemorial = false
        self.iconSystemName = nil
        self.tintHex = nil
        self.importanceLevel = 0
        self.showOnHome = true
        self.pinToTop = false
        self.isArchived = false
        self.archivedAt = nil
        self.reminderPresetRawValues = []
        self.allDayReminderHour = 9
        self.allDayReminderMinute = 0
        self.createdAt = now
        self.updatedAt = now
        self.notebook = notebook
        self.tags = []
    }

    init(
        id: UUID = UUID(),
        title: String,
        note: String? = nil,
        targetDate: Date,
        allDay: Bool,
        isMemorial: Bool = false,
        iconSystemName: String? = nil,
        tintHex: String? = nil,
        importanceLevel: Int = 0,
        showOnHome: Bool = true,
        pinToTop: Bool = false,
        isArchived: Bool = false,
        archivedAt: Date? = nil,
        reminderPresets: [EventReminderPreset] = [],
        allDayReminderHour: Int = 9,
        allDayReminderMinute: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        notebook: Notebook? = nil,
        tags: [Tag] = []
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.targetDate = targetDate
        self.allDay = allDay
        self.isMemorial = isMemorial
        self.iconSystemName = iconSystemName
        self.tintHex = tintHex
        self.importanceLevel = importanceLevel
        self.showOnHome = showOnHome
        self.pinToTop = pinToTop
        self.isArchived = isArchived
        self.archivedAt = archivedAt
        self.reminderPresetRawValues = reminderPresets.map(\.rawValue)
        self.allDayReminderHour = allDayReminderHour
        self.allDayReminderMinute = allDayReminderMinute
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.notebook = notebook
        self.tags = tags
    }
}
