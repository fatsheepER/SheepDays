//
//  LastFocusStateStore.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/5/21.
//

import Foundation

struct LastFocusStateStore: @unchecked Sendable {
    static let shared = LastFocusStateStore()

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load(scope: Scope = .home) -> Payload? {
        guard let data = userDefaults.data(forKey: scope.storageKey) else {
            return nil
        }

        return try? Self.decoder.decode(Payload.self, from: data)
    }

    func save(settings: FocusPresetSettings, selectedPresetID: UUID?, scope: Scope = .home) {
        let payload = Payload(settings: settings, selectedPresetID: selectedPresetID)

        do {
            let data = try Self.encoder.encode(payload)
            userDefaults.set(data, forKey: scope.storageKey)
        } catch {
            assertionFailure("Failed to persist last focus state: \(error.localizedDescription)")
        }
    }

    func clearSelectedPresetID(_ presetID: UUID) {
        for scope in Scope.allCases {
            guard var payload = load(scope: scope),
                  payload.selectedPresetID == presetID else {
                continue
            }

            payload.selectedPresetID = nil
            save(payload: payload, scope: scope)
        }
    }
}

extension LastFocusStateStore {
    enum Scope: String, CaseIterable {
        case home
        case memorial

        var storageKey: String {
            switch self {
            case .home:
                return "Focus.lastState"
            case .memorial:
                return "Focus.memorial.lastState"
            }
        }
    }

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

    func save(payload: Payload, scope: Scope) {
        do {
            let data = try Self.encoder.encode(payload)
            userDefaults.set(data, forKey: scope.storageKey)
        } catch {
            assertionFailure("Failed to persist last focus state: \(error.localizedDescription)")
        }
    }
}
