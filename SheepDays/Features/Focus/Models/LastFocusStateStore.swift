//
//  LastFocusStateStore.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/5/21.
//

import Foundation

struct LastFocusStateStore {
    static let shared = LastFocusStateStore()

    private let userDefaults: UserDefaults
    private let storageKey = "Focus.lastState"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> Payload? {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return nil
        }

        return try? Self.decoder.decode(Payload.self, from: data)
    }

    func save(settings: FocusPresetSettings, selectedPresetID: UUID?) {
        let payload = Payload(settings: settings, selectedPresetID: selectedPresetID)

        do {
            let data = try Self.encoder.encode(payload)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            assertionFailure("Failed to persist last focus state: \(error.localizedDescription)")
        }
    }
}

extension LastFocusStateStore {
    struct Payload: Codable, Equatable {
        var settingsVersion: Int
        var settings: FocusPresetSettings
        var selectedPresetID: UUID?

        init(settings: FocusPresetSettings, selectedPresetID: UUID?) {
            self.settingsVersion = FocusPresetSettings.currentVersion
            self.settings = settings
            self.selectedPresetID = selectedPresetID
        }
    }
}

private extension LastFocusStateStore {
    static let encoder = JSONEncoder()
    static let decoder = JSONDecoder()
}
