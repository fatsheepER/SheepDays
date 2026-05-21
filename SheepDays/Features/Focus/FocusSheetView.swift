//
//  FocusSheetView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import SwiftUI
import SwiftData

struct FocusSheetView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var focusState: HomeFocusState

    @Query(
        filter: #Predicate<Notebook> { !$0.isArchived },
        sort: [
            SortDescriptor(\Notebook.updatedAt, order: .reverse),
            SortDescriptor(\Notebook.createdAt, order: .reverse)
        ]
    )
    private var notebooks: [Notebook]

    @Query(
        sort: [
            SortDescriptor(\Notebook.updatedAt, order: .reverse),
            SortDescriptor(\Notebook.createdAt, order: .reverse)
        ]
    )
    private var allNotebooks: [Notebook]

    @Query(
        sort: [
            SortDescriptor(\Tag.name),
            SortDescriptor(\Tag.createdAt)
        ]
    )
    private var tags: [Tag]

    @Query(
        sort: [
            SortDescriptor(\FocusPreset.createdAt, order: .reverse)
        ]
    )
    private var presets: [FocusPreset]

    @State private var notebookShakeTrigger = 0
    @State private var tagShakeTrigger = 0
    @State private var selectedPresetID: UUID?
    @State private var isPresetNameAlertPresented = false
    @State private var presetNameDraft = ""
    @State private var presetNameError: String?
    @State private var presetActionError: String?
    @State private var isPresetActionErrorPresented = false

    let onBack: () -> Void

    // MARK: - Body
    var body: some View {
        VStack(spacing: 10) {
            header

            VStack(spacing: 10) {
                sourceRange
//                    .layoutPriority(1.5)

                timeRange
//                    .layoutPriority(1.5)

                HStack(spacing: 10) {
                    sortMode

                    groupingMode
                }
//                .layoutPriority(1.2)
                
                Button {
                    // open advanced settings
                } label: {
                    advanced
                }
//                .layoutPriority(1.0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            controls
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert(presetNameAlertTitle, isPresented: $isPresetNameAlertPresented) {
            TextField("预设名称", text: $presetNameDraft)

            Button("取消", role: .cancel) {
                presetNameError = nil
            }

            Button("保存", action: savePresetFromDraft)
                .disabled(trimmedPresetNameDraft.isEmpty)
        } message: {
            if let presetNameError {
                Text(presetNameError)
            }
        }
        .alert("预设操作失败", isPresented: $isPresetActionErrorPresented) {
            Button("好", role: .cancel) {}
        } message: {
            Text(presetActionError ?? "")
        }
    }
}

private extension FocusSheetView {
    // MARK: - Subviews
    var header: some View {
        HStack {
            SDSheetTitleView(iconSystemName: "eye", title: "聚焦")

            Spacer()

            if let selectedPresetBadgeContent {
                FocusPresetBadge(content: selectedPresetBadgeContent)
                    .id(selectedPresetBadgeContent.id)
                    .transition(.move(edge: .bottom).combined(with: .blurReplace))
            }

            Text(summaryText)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .foregroundStyle(Color(.secondarySystemBackground))
                )
        }
        .animation(.snappy(duration: 0.18), value: selectedPresetID)
    }

    var sourceRange: some View {
        VStack(spacing: 10) {
            FocusAreaTitleView(iconSystemName: "tray.full", title: "来源范围")

            VStack(spacing: 10) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if notebooks.isEmpty {
                            emptyBadgeRow(text: "暂无事件本")
                        } else {
                            ForEach(notebooks) { notebook in
                                SDNotebookBadge(
                                    notebook: notebook,
                                    isSelected: focusState.notebookSourceFilter.includes(id: notebook.id)
                                )
                                .contentShape(Rectangle())
                                .modifier(FocusBadgeShakeModifier(trigger: CGFloat(notebookShakeTrigger)))
                                .gesture(
                                    exclusiveTapGesture(
                                        onSingleTap: { toggleNotebookSelection(notebook) },
                                        onDoubleTap: { toggleAllNotebooks() }
                                    )
                                )
                            }
                        }
                    }
                    .frame(height: 40)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if tags.isEmpty {
                            emptyBadgeRow(text: "暂无标签")
                        } else {
                            ForEach(tags) { tag in
                                SDTagBadge(
                                    tag: tag,
                                    isSelected: focusState.tagSourceFilter.includes(id: tag.id)
                                )
                                .contentShape(Rectangle())
                                .modifier(FocusBadgeShakeModifier(trigger: CGFloat(tagShakeTrigger)))
                                .gesture(
                                    exclusiveTapGesture(
                                        onSingleTap: { toggleTagSelection(tag) },
                                        onDoubleTap: { toggleAllTags() }
                                    )
                                )
                            }
                        }
                    }
                    .frame(height: 40)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(10)
        .frame(maxHeight: .infinity)
        .background(
            SDRoundedBackground(
                topLeading: 35,
                topTrailing: 35,
                bottomLeading: 10,
                bottomTrailing: 10,
                cornerStyle: .continuous,
                color: sectionBackgroundColor
            )
        )
    }

    @ViewBuilder
    func emptyBadgeRow(text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color(.tertiaryLabel))
            .padding(.horizontal, 10)
            .frame(height: 35)
    }

    var timeRange: some View {
        VStack {
            FocusAreaTitleView(iconSystemName: "clock", title: "时间范围")

            VStack {
                HStack {
                    ForEach(HomeFocusTimeRange.allCases, id: \.self) { range in
                        Button {
                            selectTimeRange(range)
                        } label: {
                            Text(range.title)
                        }
                        .foregroundStyle(
                            focusState.timeRange == range
                            ? Color.accentColor
                            : Color(.tertiaryLabel)
                        )

                        if range != .all {
                            Spacer()
                        }
                    }
                }
                .font(.system(size: 20, weight: .semibold))
                .buttonStyle(.plain)
                .padding(.horizontal, 30)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            SDRoundedBackground(
                topLeading: 10,
                topTrailing: 10,
                bottomLeading: 10,
                bottomTrailing: 10,
                cornerStyle: .continuous,
                color: sectionBackgroundColor
            )
        )
    }

    var sortMode: some View {
        VStack(spacing: 10) {
            FocusAreaTitleView(iconSystemName: "arrow.up.arrow.down", title: "排序方式")
            
            HStack {
                Menu {
                    ForEach(FocusSortField.allCases, id: \.self) { field in
                        Button {
                            selectSortField(field)
                        } label: {
                            selectionMenuLabel(
                                title: field.title,
                                isSelected: field == selectedSortField
                            )
                        }
                    }
                } label: {
                    selectionMenuTrigger(
                        title: selectedSortField.title,
                        reservedTitle: FocusSortField.longestTitle
                    )
                }
                
                Circle().frame(width: 3)
                    .foregroundStyle(.accent.opacity(0.5))
                
                Menu {
                    ForEach(FocusSortDirection.allCases, id: \.self) { direction in
                        Button {
                            selectSortDirection(direction)
                        } label: {
                            selectionMenuLabel(
                                title: direction.title,
                                isSelected: direction == selectedSortDirection
                            )
                        }
                    }
                } label: {
                    selectionMenuTrigger(
                        title: selectedSortDirection.title,
                        reservedTitle: FocusSortDirection.longestTitle
                    )
                }
            }
            .font(.system(size: 18, weight: .semibold))
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            SDRoundedBackground(
                topLeading: 10,
                topTrailing: 10,
                bottomLeading: 10,
                bottomTrailing: 10,
                cornerStyle: .continuous,
                color: sectionBackgroundColor)
        )
    }

    var groupingMode: some View {
        VStack(spacing: 10) {
            FocusAreaTitleView(iconSystemName: "square.grid.3x1.below.line.grid.1x2", title: "分组样式")
            
            Menu {
                ForEach(HomeGroupingMode.allCases, id: \.self) { mode in
                    Button {
                        selectGroupingMode(mode)
                    } label: {
                        selectionMenuLabel(
                            title: mode.title,
                            isSelected: mode == focusState.groupingMode
                        )
                    }
                }
            } label: {
                selectionMenuTrigger(
                    title: focusState.groupingMode.title,
                    reservedTitle: HomeGroupingMode.longestTitle
                )
            }
            .font(.system(size: 18, weight: .semibold))
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            SDRoundedBackground(
                topLeading: 10,
                topTrailing: 10,
                bottomLeading: 10,
                bottomTrailing: 10,
                cornerStyle: .continuous,
                color: sectionBackgroundColor)
        )
    }
    
    var advanced: some View {
        VStack(spacing: 10) {
            FocusAreaTitleView(iconSystemName: "gearshape.2", title: "高级选项")
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            SDRoundedBackground(topLeading: 10, topTrailing: 10, bottomLeading: 10, bottomTrailing: 10, cornerStyle: .continuous, color: sectionBackgroundColor)
        )
    }

    var controls: some View {
        HStack {
            Button(action: onBack) {
                SDSheetActionButton(
                    iconSystemName: "arrow.left",
                    title: "返回",
                    placement: .left,
                    style: .plain
                )
            }
            .buttonStyle(.plain)

            Menu {
                presetMenuContent
            } label: {
                SDSheetActionButton(
                    iconSystemName: "slider.horizontal.3",
                    title: "预设",
                    placement: .right,
                    style: .prominent
                )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    var presetMenuContent: some View {
        // 4. Restore to default
        Button {
            restoreDefaultFocus()
        } label: {
            Label("恢复默认", systemImage: "arrow.counterclockwise")
        }
        
        // 3. Delete preset
        if let selectedPreset {
            Button(role: .destructive) {
                deletePreset(selectedPreset)
            } label: {
                Label("删除预设", systemImage: "trash")
            }
        }
        
        // 2. Save as preset
        Button {
            presentPresetNameAlert()
        } label: {
            Label("保存当前为预设", systemImage: "plus")
        }

        
        // 1. Presets
        Menu {
            if presets.isEmpty {
                Button("暂无预设") {}
                    .disabled(true)
            } else {
                ForEach(presets) { preset in
                    Button {
                        selectPreset(preset)
                    } label: {
                        selectionMenuLabel(
                            title: preset.name,
                            isSelected: preset.id == selectedPresetID
                        )
                    }
                }
            }
        } label: {
            Label("选择预设...", systemImage: "list.bullet")
        }
    }

    // MARK: - Computed variables
    var summaryText: String {
        "\(activeFilterCount) 项"
    }

    var selectedPreset: FocusPreset? {
        guard let selectedPresetID else {
            return nil
        }

        return presets.first { $0.id == selectedPresetID }
    }

    var selectedPresetBadgeContent: FocusPresetBadge.Content? {
        guard let selectedPreset else {
            return nil
        }

        return FocusPresetBadge.Content(
            id: selectedPreset.id,
            title: selectedPreset.name,
            colorHex: selectedPreset.colorHex
        )
    }

    var trimmedPresetNameDraft: String {
        presetNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var presetNameAlertTitle: String {
        presetNameError == nil ? "保存预设" : "预设名称不可用"
    }

    var activeFilterCount: Int {
        var count = 0

        if !focusState.notebookSourceFilter.isDefault {
            count += 1
        }

        if !focusState.tagSourceFilter.isDefault {
            count += 1
        }

        if focusState.timeRange != .all {
            count += 1
        }

        if focusState.sortMode != .targetDateAscending {
            count += 1
        }

        if focusState.groupingMode != .none {
            count += 1
        }

        return count
    }

    var allNotebookIDs: Set<UUID> {
        Set(notebooks.map(\.id))
    }

    var allTagIDs: Set<UUID> {
        Set(tags.map(\.id))
    }

    var selectedSortField: FocusSortField {
        switch focusState.sortMode {
        case .importanceDescending, .importanceAscending:
            return .importance
        case .targetDateDescending, .targetDateAscending:
            return .targetDate
        case .createdAtDescending, .createdAtAscending:
            return .createdAt
        case .updatedAtDescending, .updatedAtAscending:
            return .updatedAt
        }
    }

    var selectedSortDirection: FocusSortDirection {
        switch focusState.sortMode {
        case .importanceDescending, .targetDateDescending, .createdAtDescending, .updatedAtDescending:
            return .descending
        case .importanceAscending, .targetDateAscending, .createdAtAscending, .updatedAtAscending:
            return .ascending
        }
    }

    // MARK: - Functions
    func exclusiveTapGesture(
        onSingleTap: @escaping () -> Void,
        onDoubleTap: @escaping () -> Void
    ) -> some Gesture {
        TapGesture(count: 2)
            .onEnded(onDoubleTap)
            .exclusively(before: TapGesture(count: 1).onEnded(onSingleTap))
    }

    func toggleNotebookSelection(_ notebook: Notebook) {
        var nextState = focusState
        nextState.notebookSourceFilter = focusState.notebookSourceFilter.toggleSingle(
            id: notebook.id,
            allIDs: allNotebookIDs
        )
        applyFocusStateChange(nextState)
    }

    func toggleAllNotebooks() {
        let nextFilter = focusState.notebookSourceFilter.toggleBulk(allIDs: allNotebookIDs)
        guard nextFilter != focusState.notebookSourceFilter else {
            return
        }

        withAnimation(.easeInOut(duration: 0.26)) {
            selectedPresetID = nil
            focusState.notebookSourceFilter = nextFilter
            notebookShakeTrigger += 1
        }
    }

    func toggleTagSelection(_ tag: Tag) {
        var nextState = focusState
        nextState.tagSourceFilter = focusState.tagSourceFilter.toggleSingle(
            id: tag.id,
            allIDs: allTagIDs
        )
        applyFocusStateChange(nextState)
    }

    func toggleAllTags() {
        let nextFilter = focusState.tagSourceFilter.toggleBulk(allIDs: allTagIDs)
        guard nextFilter != focusState.tagSourceFilter else {
            return
        }

        withAnimation(.easeInOut(duration: 0.26)) {
            selectedPresetID = nil
            focusState.tagSourceFilter = nextFilter
            tagShakeTrigger += 1
        }
    }

    func selectTimeRange(_ range: HomeFocusTimeRange) {
        guard focusState.timeRange != range else {
            return
        }

        var nextState = focusState
        nextState.timeRange = range
        applyFocusStateChange(nextState)
    }

    @ViewBuilder
    func selectionMenuLabel(title: String, isSelected: Bool) -> some View {
        HStack {
            Text(title)

            if isSelected {
                Spacer()
                Image(systemName: "checkmark")
            }
        }
    }

    @ViewBuilder
    func selectionMenuTrigger(title: String, reservedTitle: String) -> some View {
        ZStack {
            Text(reservedTitle)
                .hidden()

            Text(title)
                .lineLimit(1)
        }
    }

    func selectSortField(_ field: FocusSortField) {
        updateSortMode(field: field, direction: selectedSortDirection)
    }

    func selectSortDirection(_ direction: FocusSortDirection) {
        updateSortMode(field: selectedSortField, direction: direction)
    }

    func selectGroupingMode(_ mode: HomeGroupingMode) {
        guard focusState.groupingMode != mode else {
            return
        }

        var nextState = focusState
        nextState.groupingMode = mode
        applyFocusStateChange(nextState)
    }

    func updateSortMode(field: FocusSortField, direction: FocusSortDirection) {
        let nextMode: HomeSortMode

        switch (field, direction) {
        case (.importance, .descending):
            nextMode = .importanceDescending
        case (.importance, .ascending):
            nextMode = .importanceAscending
        case (.targetDate, .descending):
            nextMode = .targetDateDescending
        case (.targetDate, .ascending):
            nextMode = .targetDateAscending
        case (.createdAt, .descending):
            nextMode = .createdAtDescending
        case (.createdAt, .ascending):
            nextMode = .createdAtAscending
        case (.updatedAt, .descending):
            nextMode = .updatedAtDescending
        case (.updatedAt, .ascending):
            nextMode = .updatedAtAscending
        }

        guard focusState.sortMode != nextMode else {
            return
        }

        var nextState = focusState
        nextState.sortMode = nextMode
        applyFocusStateChange(nextState)
    }

    func applyFocusStateChange(
        _ nextState: HomeFocusState,
        animation: Animation = .snappy(duration: 0.18)
    ) {
        guard focusState != nextState else {
            return
        }

        withAnimation(animation) {
            selectedPresetID = nil
            focusState = nextState
        }
    }

    func selectPreset(_ preset: FocusPreset) {
        do {
            let settings = try preset.decodedSettings()
            let resolution = settings.resolved(notebooks: allNotebooks, tags: tags)

            if resolution.prunedSettings != settings {
                try preset.updateSettings(resolution.prunedSettings)
                try modelContext.save()
            }

            withAnimation(.snappy(duration: 0.18)) {
                selectedPresetID = preset.id
                focusState = resolution.focusState
            }
        } catch {
            showPresetActionError(error)
        }
    }

    func presentPresetNameAlert() {
        presetNameError = nil
        isPresetNameAlertPresented = true
    }

    func savePresetFromDraft() {
        let trimmedName = trimmedPresetNameDraft
        guard !trimmedName.isEmpty else {
            showPresetNameError("请输入预设名称")
            return
        }

        let normalizedName = FocusPresetSettings.normalizedName(trimmedName)
        guard presets.contains(where: { $0.normalizedName == normalizedName }) == false else {
            showPresetNameError("已存在同名预设")
            return
        }

        let settings = FocusPresetSettings.snapshot(
            from: focusState,
            notebooks: allNotebooks,
            tags: tags
        )
        let preset = FocusPreset(
            name: trimmedName,
            colorHex: randomPresetColorHex,
            settings: settings
        )

        modelContext.insert(preset)

        do {
            try modelContext.save()
            withAnimation(.snappy(duration: 0.18)) {
                selectedPresetID = preset.id
            }
            presetNameDraft = ""
            presetNameError = nil
        } catch {
            modelContext.delete(preset)
            showPresetNameError(error.localizedDescription)
        }
    }

    func showPresetNameError(_ message: String) {
        presetNameError = message
        Task { @MainActor in
            isPresetNameAlertPresented = true
        }
    }

    func deletePreset(_ preset: FocusPreset) {
        modelContext.delete(preset)

        do {
            try modelContext.save()
            withAnimation(.snappy(duration: 0.18)) {
                selectedPresetID = nil
            }
        } catch {
            showPresetActionError(error)
        }
    }

    func restoreDefaultFocus() {
        let defaultState = HomeFocusState()

        guard focusState != defaultState else {
            withAnimation(.snappy(duration: 0.18)) {
                selectedPresetID = nil
            }
            return
        }

        withAnimation(.snappy(duration: 0.18)) {
            selectedPresetID = nil
            focusState = defaultState
        }
    }

    func showPresetActionError(_ error: Error) {
        presetActionError = error.localizedDescription
        isPresetActionErrorPresented = true
    }
}

// MARK: - Style constants
private extension FocusSheetView {
    static let presetColorHexes = [
        "FF8A65",
        "5C6BC0",
        "26A69A",
        "30A2F3",
        "DA4646",
        "7E57C2"
    ]

    var sectionBackgroundColor: Color {
        Color(.quaternarySystemFill)
    }

    var randomPresetColorHex: String {
        Self.presetColorHexes.randomElement() ?? "5C6BC0"
    }
}

// MARK: - Effects
private struct FocusBadgeShakeModifier: GeometryEffect {
    var trigger: CGFloat
    var amplitude: CGFloat = 4
    var shakesPerUnit = 3

    var animatableData: CGFloat {
        get { trigger }
        set { trigger = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translationX = amplitude * sin(trigger * .pi * CGFloat(shakesPerUnit))
        return ProjectionTransform(CGAffineTransform(translationX: translationX, y: 0))
    }
}

// MARK: - Private extensions
private extension HomeGroupingMode {
    static var longestTitle: String {
        allCases
            .map(\.title)
            .max(by: { $0.count < $1.count }) ?? ""
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var focusState = HomeFocusState()

    FocusSheetView(
        focusState: $focusState,
        onBack: {}
    )
    .modelContainer(focusSheetPreviewContainer)
    .padding()
    .background {
        Color(.secondarySystemBackground)
            .ignoresSafeArea()
    }
}

private let focusSheetPreviewContainer: ModelContainer = {
    let container = ModelContainerProvider.makePreviewContainer()
    let context = container.mainContext

    let notebooks = [
        Notebook(name: "学校", colorHex: "1B9616", iconSystemName: "book"),
        Notebook(name: "家庭", colorHex: "00AEB3", iconSystemName: "house"),
        Notebook(name: "游戏发售", colorHex: "30A2F3", iconSystemName: "dpad"),
        Notebook(name: "节日", colorHex: "DA4646", iconSystemName: "party.popper")
    ]
    let tags = [
        Tag(name: "期末考试"),
        Tag(name: "暑假计划"),
        Tag(name: "作业"),
        Tag(name: "课程项目"),
        Tag(name: "好吃的")
    ]

    notebooks.forEach(context.insert)
    tags.forEach(context.insert)

    return container
}()
