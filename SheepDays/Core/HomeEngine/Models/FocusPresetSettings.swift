//
//  FocusPresetSettings.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/5/21.
//

import Foundation

nonisolated struct FocusPresetSettings: Codable, Equatable {
    static let currentVersion = 1

    var selectedNotebookIDs: Set<UUID>
    var tagSelection: TagSelection
    var timeRange: HomeFocusTimeRange
    var sortMode: HomeSortMode
    var groupingMode: HomeGroupingMode

    init(
        selectedNotebookIDs: Set<UUID>,
        tagSelection: TagSelection,
        timeRange: HomeFocusTimeRange,
        sortMode: HomeSortMode,
        groupingMode: HomeGroupingMode
    ) {
        self.selectedNotebookIDs = selectedNotebookIDs
        self.tagSelection = tagSelection
        self.timeRange = timeRange
        self.sortMode = sortMode
        self.groupingMode = groupingMode
    }
}

extension FocusPresetSettings {
    nonisolated enum TagSelection: Codable, Equatable {
        case selectedNames([String])
        case untaggedOnly
    }

    nonisolated struct Resolution {
        let focusState: HomeFocusState
        let prunedSettings: FocusPresetSettings
    }

    static func snapshot(
        from focusState: HomeFocusState,
        notebooks: [Notebook],
        tags: [Tag]
    ) -> FocusPresetSettings {
        FocusPresetSettings(
            selectedNotebookIDs: notebookIDsSnapshot(
                from: focusState.notebookSourceFilter,
                notebooks: notebooks
            ),
            tagSelection: tagSelectionSnapshot(
                from: focusState.tagSourceFilter,
                tags: tags
            ),
            timeRange: focusState.timeRange,
            sortMode: focusState.sortMode,
            groupingMode: focusState.groupingMode
        )
    }

    func resolved(notebooks: [Notebook], tags: [Tag]) -> Resolution {
        let existingNotebookIDs = Set(notebooks.map(\.id))
        let prunedNotebookIDs = selectedNotebookIDs.intersection(existingNotebookIDs)

        let focusState = HomeFocusState(
            notebookSourceFilter: .explicitSnapshotSelection(prunedNotebookIDs),
            tagSourceFilter: resolvedTagSourceFilter(tags: tags),
            timeRange: timeRange,
            sortMode: sortMode,
            groupingMode: groupingMode
        )

        let prunedSettings = FocusPresetSettings(
            selectedNotebookIDs: prunedNotebookIDs,
            tagSelection: tagSelection,
            timeRange: timeRange,
            sortMode: sortMode,
            groupingMode: groupingMode
        )

        return Resolution(focusState: focusState, prunedSettings: prunedSettings)
    }

    nonisolated static func normalizedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

private extension FocusPresetSettings {
    static func notebookIDsSnapshot(
        from filter: HomeNotebookSourceFilter,
        notebooks: [Notebook]
    ) -> Set<UUID> {
        switch filter {
        case .all:
            return Set(notebooks.map(\.id))
        case let .selected(ids):
            return ids
        case .none:
            return []
        }
    }

    static func tagSelectionSnapshot(
        from filter: HomeTagSourceFilter,
        tags: [Tag]
    ) -> TagSelection {
        switch filter {
        case .all:
            return .selectedNames(normalizedUniqueTagNames(from: tags))
        case let .selected(ids):
            let selectedTags = tags.filter { ids.contains($0.id) }
            return .selectedNames(normalizedUniqueTagNames(from: selectedTags))
        case .none:
            return .selectedNames([])
        case .untaggedOnly:
            return .untaggedOnly
        }
    }

    static func normalizedUniqueTagNames(from tags: [Tag]) -> [String] {
        var seenNames: Set<String> = []
        var names: [String] = []

        for tag in tags {
            let normalizedName = normalizedName(tag.name)
            guard !normalizedName.isEmpty,
                  !seenNames.contains(normalizedName) else {
                continue
            }

            seenNames.insert(normalizedName)
            names.append(tag.name.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return names
    }

    func resolvedTagSourceFilter(tags: [Tag]) -> HomeTagSourceFilter {
        switch tagSelection {
        case .untaggedOnly:
            return .untaggedOnly
        case let .selectedNames(names):
            let normalizedSelectedNames = Set(
                names
                    .map(Self.normalizedName)
                    .filter { !$0.isEmpty }
            )
            let selectedTagIDs = Set(
                tags
                    .filter { normalizedSelectedNames.contains(Self.normalizedName($0.name)) }
                    .map(\.id)
            )
            return .explicitSnapshotSelection(selectedTagIDs)
        }
    }
}

extension HomeNotebookSourceFilter {
    static func explicitSnapshotSelection(_ ids: Set<UUID>) -> HomeNotebookSourceFilter {
        ids.isEmpty ? .none : .selected(ids)
    }
}

extension HomeTagSourceFilter {
    static func explicitSnapshotSelection(_ ids: Set<UUID>) -> HomeTagSourceFilter {
        ids.isEmpty ? .none : .selected(ids)
    }
}
