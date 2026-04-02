//
//  Tag.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import Foundation
import SwiftData

@Model
final class Tag {
    @Attribute(.unique) var id: UUID
    var name: String
    var normalizedName: String
    var colorHex: String?
    var iconSystemName: String?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .nullify) var events: [Event]

    init(
        name: String,
        colorHex: String? = nil,
        iconSystemName: String? = nil
    ) {
        let now = Date()
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        self.id = UUID()
        self.name = trimmedName
        self.normalizedName = trimmedName.lowercased()
        self.colorHex = colorHex
        self.iconSystemName = iconSystemName
        self.createdAt = now
        self.updatedAt = now
        self.events = []
    }
}
