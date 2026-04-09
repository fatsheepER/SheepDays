//
//  Notebook.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Notebook {
    @Attribute(.unique) var id: UUID
    var name: String
    var note: String?
    var colorHex: String?
    var iconSystemName: String?
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .nullify) var events: [Event]

    init(
        name: String,
        note: String? = nil,
        colorHex: String? = nil,
        iconSystemName: String? = nil,
        isArchived: Bool = false
    ) {
        let now = Date()
        self.id = UUID()
        self.name = name
        self.note = note
        self.colorHex = colorHex
        self.iconSystemName = iconSystemName
        self.isArchived = isArchived
        self.createdAt = now
        self.updatedAt = now
        self.events = []
    }

    var tintColor: Color {
        guard let colorHex,
              let color = Color(hex: colorHex) else {
            return .accentColor
        }

        return color
    }
}
