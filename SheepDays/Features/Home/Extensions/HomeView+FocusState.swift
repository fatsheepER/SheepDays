//
//  HomeView+FocusState.swift
//  SheepDays
//
//  Created by Codex on 2026/6/12.
//

import SwiftUI
import SwiftData

extension HomeView {
    var activeFocusScope: LastFocusStateStore.Scope {
        activeHomeContentPage == .expiredMemorials ? .memorial : .home
    }

    var activeFocusDefaultState: HomeFocusState {
        switch activeFocusScope {
        case .home:
            return HomeFocusState()
        case .memorial:
            return .memorialDefault
        }
    }

    var activeFocusStateBinding: Binding<HomeFocusState> {
        Binding(
            get: {
                switch activeFocusScope {
                case .home:
                    return homeFocusState
                case .memorial:
                    return memorialFocusState
                }
            },
            set: { newValue in
                switch activeFocusScope {
                case .home:
                    homeFocusState = newValue
                case .memorial:
                    memorialFocusState = newValue
                }
            }
        )
    }

    var activeSelectedFocusPresetIDBinding: Binding<UUID?> {
        Binding(
            get: {
                switch activeFocusScope {
                case .home:
                    return homeSelectedFocusPresetID
                case .memorial:
                    return memorialSelectedFocusPresetID
                }
            },
            set: { newValue in
                switch activeFocusScope {
                case .home:
                    homeSelectedFocusPresetID = newValue
                case .memorial:
                    memorialSelectedFocusPresetID = newValue
                }
            }
        )
    }

    func restoreLastFocusStatesIfNeeded() {
        guard !hasRestoredLastFocusStates else {
            return
        }

        hasRestoredLastFocusStates = true

        do {
            let notebooks = try modelContext.fetch(FetchDescriptor<Notebook>())
            let tags = try modelContext.fetch(FetchDescriptor<Tag>())

            restoreLastFocusStateIfNeeded(for: .home, notebooks: notebooks, tags: tags)
            restoreLastFocusStateIfNeeded(for: .memorial, notebooks: notebooks, tags: tags)
        } catch {
            assertionFailure("Failed to restore last focus states: \(error.localizedDescription)")
        }
    }

    func restoreLastFocusStateIfNeeded(
        for scope: LastFocusStateStore.Scope,
        notebooks: [Notebook],
        tags: [Tag]
    ) {
        guard let payload = LastFocusStateStore.shared.load(scope: scope) else {
            return
        }

        if let presetID = payload.selectedPresetID,
           restoreLastFocusState(fromPresetID: presetID, scope: scope, notebooks: notebooks, tags: tags) {
            return
        }

        let resolution = payload.settings.resolved(notebooks: notebooks, tags: tags)
        setFocusState(resolution.focusState, selectedPresetID: nil, for: scope)
        LastFocusStateStore.shared.save(
            settings: resolution.prunedSettings,
            selectedPresetID: nil,
            scope: scope
        )
    }

    func restoreLastFocusState(
        fromPresetID presetID: UUID,
        scope: LastFocusStateStore.Scope,
        notebooks: [Notebook],
        tags: [Tag]
    ) -> Bool {
        do {
            let predicate = #Predicate<FocusPreset> { preset in
                preset.id == presetID
            }
            var descriptor = FetchDescriptor<FocusPreset>(predicate: predicate)
            descriptor.fetchLimit = 1

            guard let preset = try modelContext.fetch(descriptor).first else {
                return false
            }

            let settings = try preset.decodedSettings()
            let resolution = settings.resolved(notebooks: notebooks, tags: tags)

            if resolution.prunedSettings != settings {
                try preset.updateSettings(resolution.prunedSettings)
                try modelContext.save()
            }

            setFocusState(resolution.focusState, selectedPresetID: preset.id, for: scope)
            LastFocusStateStore.shared.save(
                settings: resolution.prunedSettings,
                selectedPresetID: preset.id,
                scope: scope
            )
            return true
        } catch {
            assertionFailure("Failed to restore focus preset: \(error.localizedDescription)")
            return false
        }
    }

    func setFocusState(
        _ focusState: HomeFocusState,
        selectedPresetID: UUID?,
        for scope: LastFocusStateStore.Scope
    ) {
        switch scope {
        case .home:
            homeFocusState = focusState
            homeSelectedFocusPresetID = selectedPresetID
        case .memorial:
            memorialFocusState = focusState
            memorialSelectedFocusPresetID = selectedPresetID
        }
    }

    func handleFocusPresetDeleted(_ presetID: UUID) {
        if homeSelectedFocusPresetID == presetID {
            homeSelectedFocusPresetID = nil
        }

        if memorialSelectedFocusPresetID == presetID {
            memorialSelectedFocusPresetID = nil
        }
    }
}
