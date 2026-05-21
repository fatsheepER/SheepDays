//
//  FocusPresetSettings.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/5/21.
//

import Foundation

nonisolated struct FocusPresetSettings: Codable, Equatable {
    static let currentVersion = 2

    var notebookSelection: NotebookSelection
    var tagSelection: TagSelection
    var timeRange: HomeFocusTimeRange
    var sortMode: HomeSortMode
    var groupingMode: HomeGroupingMode

    init(
        notebookSelection: NotebookSelection,
        tagSelection: TagSelection,
        timeRange: HomeFocusTimeRange,
        sortMode: HomeSortMode,
        groupingMode: HomeGroupingMode
    ) {
        self.notebookSelection = notebookSelection
        self.tagSelection = tagSelection
        self.timeRange = timeRange
        self.sortMode = sortMode
        self.groupingMode = groupingMode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let notebookSelection = try container.decodeIfPresent(NotebookSelection.self, forKey: .notebookSelection) {
            self.notebookSelection = notebookSelection
        } else {
            let legacyNotebookIDs = try container.decode(Set<UUID>.self, forKey: .selectedNotebookIDs)
            self.notebookSelection = .explicitSnapshotSelection(legacyNotebookIDs)
        }

        tagSelection = try container.decode(TagSelection.self, forKey: .tagSelection)
        timeRange = try container.decode(HomeFocusTimeRange.self, forKey: .timeRange)
        sortMode = try container.decode(HomeSortMode.self, forKey: .sortMode)
        groupingMode = try container.decode(HomeGroupingMode.self, forKey: .groupingMode)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(notebookSelection, forKey: .notebookSelection)
        try container.encode(tagSelection, forKey: .tagSelection)
        try container.encode(timeRange, forKey: .timeRange)
        try container.encode(sortMode, forKey: .sortMode)
        try container.encode(groupingMode, forKey: .groupingMode)
    }
}

extension FocusPresetSettings {
    nonisolated enum NotebookSelection: Codable, Equatable {
        case all
        case selectedIDs(Set<UUID>)
        case none
    }

    nonisolated enum TagSelection: Codable, Equatable {
        case all
        case selectedNames([String])
        case none
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
            notebookSelection: notebookSelectionSnapshot(
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
        let resolvedNotebookSelection = notebookSelection.pruned(existingNotebookIDs: existingNotebookIDs)

        let focusState = HomeFocusState(
            notebookSourceFilter: resolvedNotebookSelection.sourceFilter,
            tagSourceFilter: resolvedTagSourceFilter(tags: tags),
            timeRange: timeRange,
            sortMode: sortMode,
            groupingMode: groupingMode
        )

        let prunedSettings = FocusPresetSettings(
            notebookSelection: resolvedNotebookSelection,
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
    enum CodingKeys: String, CodingKey {
        case notebookSelection
        case selectedNotebookIDs
        case tagSelection
        case timeRange
        case sortMode
        case groupingMode
    }
}

private extension FocusPresetSettings {
    static func notebookSelectionSnapshot(
        from filter: HomeNotebookSourceFilter,
        notebooks: [Notebook]
    ) -> NotebookSelection {
        switch filter {
        case .all:
            return .all
        case let .selected(ids):
            return .selectedIDs(ids.intersection(Set(notebooks.map(\.id))))
        case .none:
            return .none
        }
    }

    static func tagSelectionSnapshot(
        from filter: HomeTagSourceFilter,
        tags: [Tag]
    ) -> TagSelection {
        switch filter {
        case .all:
            return .all
        case let .selected(ids):
            let selectedTags = tags.filter { ids.contains($0.id) }
            return .selectedNames(normalizedUniqueTagNames(from: selectedTags))
        case .none:
            return .none
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
        case .all:
            return .all
        case .none:
            return .none
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

private extension FocusPresetSettings.NotebookSelection {
    static func explicitSnapshotSelection(_ ids: Set<UUID>) -> FocusPresetSettings.NotebookSelection {
        ids.isEmpty ? .none : .selectedIDs(ids)
    }

    var sourceFilter: HomeNotebookSourceFilter {
        switch self {
        case .all:
            return .all
        case let .selectedIDs(ids):
            return .explicitSnapshotSelection(ids)
        case .none:
            return .none
        }
    }

    func pruned(existingNotebookIDs: Set<UUID>) -> FocusPresetSettings.NotebookSelection {
        switch self {
        case .all, .none:
            return self
        case let .selectedIDs(ids):
            return .explicitSnapshotSelection(ids.intersection(existingNotebookIDs))
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
