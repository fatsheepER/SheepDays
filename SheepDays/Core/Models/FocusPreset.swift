//
//  FocusPreset.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/5/21.
//

import Foundation
import SwiftData

@Model
final class FocusPreset {
    @Attribute(.unique) var id: UUID
    var name: String
    @Attribute(.unique) var normalizedName: String
    var colorHex: String
    var createdAt: Date
    var updatedAt: Date
    var settingsVersion: Int
    var settingsData: Data

    init(
        name: String,
        colorHex: String,
        settings: FocusPresetSettings
    ) {
        let now = Date()
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        self.id = UUID()
        self.name = trimmedName
        self.normalizedName = FocusPresetSettings.normalizedName(trimmedName)
        self.colorHex = colorHex
        self.createdAt = now
        self.updatedAt = now
        self.settingsVersion = FocusPresetSettings.currentVersion
        self.settingsData = (try? Self.encoder.encode(settings)) ?? Data()
    }

    func decodedSettings() throws -> FocusPresetSettings {
        try Self.decoder.decode(FocusPresetSettings.self, from: settingsData)
    }

    func updateSettings(_ settings: FocusPresetSettings) throws {
        settingsData = try Self.encoder.encode(settings)
        settingsVersion = FocusPresetSettings.currentVersion
        updatedAt = Date()
    }
}

private extension FocusPreset {
    static let encoder = JSONEncoder()
    static let decoder = JSONDecoder()
}
