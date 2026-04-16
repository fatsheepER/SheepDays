//
//  FocusSheetView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import SwiftUI
import SwiftData

private enum FocusSortField: CaseIterable {
    case importance
    case targetDate
    case createdAt
    case updatedAt

    var title: String {
        switch self {
        case .importance:
            return "按重要程度"
        case .targetDate:
            return "按日期"
        case .createdAt:
            return "按创建时间"
        case .updatedAt:
            return "按编辑时间"
        }
    }

    static var longestTitle: String {
        allCases
            .map(\.title)
            .max(by: { $0.count < $1.count }) ?? ""
    }
}

private enum FocusSortDirection: CaseIterable {
    case descending
    case ascending

    var title: String {
        switch self {
        case .descending:
            return "降序"
        case .ascending:
            return "升序"
        }
    }

    static var longestTitle: String {
        allCases
            .map(\.title)
            .max(by: { $0.count < $1.count }) ?? ""
    }
}

struct FocusSheetView: View {
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
            SortDescriptor(\Tag.name),
            SortDescriptor(\Tag.createdAt)
        ]
    )
    private var tags: [Tag]

    @State private var isShowingAdvancedOptions = false
    @State private var notebookShakeTrigger = 0
    @State private var tagShakeTrigger = 0

    let onBack: () -> Void

    // MARK: - Body
    var body: some View {
        VStack(spacing: 10) {
            header

            Group {
                if isShowingAdvancedOptions {
                    advancedOptionsPlaceholder
                } else {
                    VStack(spacing: 10) {
                        sourceRange

                        timeRange

                        HStack(spacing: 10) {
                            sortMode

                            groupingMode
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            controls
                .frame(height: 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private extension FocusSheetView {
    // MARK: - Subviews
    var header: some View {
        HStack {
            SDSheetTitleView(iconSystemName: "eye", title: "聚焦")

            Spacer()

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
                color: Color(.systemBackground).opacity(0.6)
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
                color: Color(.systemBackground).opacity(0.6)
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
                            sortMenuLabel(
                                title: field.title,
                                isSelected: field == selectedSortField
                            )
                        }
                    }
                } label: {
                    sortMenuTrigger(
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
                            sortMenuLabel(
                                title: direction.title,
                                isSelected: direction == selectedSortDirection
                            )
                        }
                    }
                } label: {
                    sortMenuTrigger(
                        title: selectedSortDirection.title,
                        reservedTitle: FocusSortDirection.longestTitle
                    )
                }
            }
            .font(.system(size: 18, weight: .semibold))
            .padding(.vertical, 10)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(
            SDRoundedBackground(
                topLeading: 10,
                topTrailing: 10,
                bottomLeading: 10,
                bottomTrailing: 10,
                cornerStyle: .continuous,
                color: Color(.systemBackground)).opacity(0.6)
        )
    }

    var groupingMode: some View {
        VStack(spacing: 10) {
            FocusAreaTitleView(iconSystemName: "square.grid.3x1.below.line.grid.1x2", title: "分组样式")
            
            // content
            Menu {
                
            } label: {
                HStack {
                    Text("按事件本")
                }
                .font(.system(size: 18, weight: .semibold))
            }
            .padding(.vertical, 10)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(
            SDRoundedBackground(
                topLeading: 10,
                topTrailing: 10,
                bottomLeading: 10,
                bottomTrailing: 10,
                cornerStyle: .continuous,
                color: Color(.systemBackground)).opacity(0.6)
        )
    }

    // MARK: - Placeholder
    var advancedOptionsPlaceholder: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                placeholderRow(
                    title: "来源范围",
                    detail: "事件本与标签的高级配置稍后接入"
                )
                placeholderRow(
                    title: "时间范围",
                    detail: "精细时间窗口规则稍后接入"
                )
                placeholderRow(
                    title: "排序方式",
                    detail: "排序条件的高级选项稍后接入"
                )
                placeholderRow(
                    title: "分组方式",
                    detail: "分组条件的高级选项稍后接入"
                )
            }
        }
    }

    func placeholderRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            Text(detail)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            SDRoundedBackground(
                topLeading: 24,
                topTrailing: 24,
                bottomLeading: 10,
                bottomTrailing: 10,
                cornerStyle: .continuous,
                color: Color(.systemBackground)
            )
        )
    }

    var controls: some View {
        HStack {
            Button(action: restorePreset) {
                SDSheetActionButton(
                    iconSystemName: "arrow.counterclockwise",
                    title: "还原",
                    placement: .left,
                    style: .destructive
                )
            }
            .buttonStyle(.plain)

            Button(action: toggleAdvancedOptions) {
                SDSheetActionButton(
                    iconSystemName: isShowingAdvancedOptions ? "chevron.down" : "ellipsis",
                    title: isShowingAdvancedOptions ? "收起" : "更多",
                    placement: .middle,
                    style: .plain
                )
            }
            .buttonStyle(.plain)

            Button(action: onBack) {
                SDSheetActionButton(
                    iconSystemName: "checkmark",
                    title: "应用",
                    placement: .right,
                    style: .prominent
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Computed variables
    var summaryText: String {
        "\(activeFilterCount) 项"
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
        withAnimation(.snappy(duration: 0.18)) {
            focusState.notebookSourceFilter = focusState.notebookSourceFilter.toggleSingle(
                id: notebook.id,
                allIDs: allNotebookIDs
            )
        }
    }

    func toggleAllNotebooks() {
        let nextFilter = focusState.notebookSourceFilter.toggleBulk(allIDs: allNotebookIDs)
        guard nextFilter != focusState.notebookSourceFilter else {
            return
        }

        withAnimation(.easeInOut(duration: 0.26)) {
            focusState.notebookSourceFilter = nextFilter
            notebookShakeTrigger += 1
        }
    }

    func toggleTagSelection(_ tag: Tag) {
        withAnimation(.snappy(duration: 0.18)) {
            focusState.tagSourceFilter = focusState.tagSourceFilter.toggleSingle(
                id: tag.id,
                allIDs: allTagIDs
            )
        }
    }

    func toggleAllTags() {
        let nextFilter = focusState.tagSourceFilter.toggleBulk(allIDs: allTagIDs)
        guard nextFilter != focusState.tagSourceFilter else {
            return
        }

        withAnimation(.easeInOut(duration: 0.26)) {
            focusState.tagSourceFilter = nextFilter
            tagShakeTrigger += 1
        }
    }

    func selectTimeRange(_ range: HomeFocusTimeRange) {
        guard focusState.timeRange != range else {
            return
        }

        withAnimation(.snappy(duration: 0.18)) {
            focusState.timeRange = range
        }
    }

    @ViewBuilder
    func sortMenuLabel(title: String, isSelected: Bool) -> some View {
        HStack {
            Text(title)

            if isSelected {
                Spacer()
                Image(systemName: "checkmark")
            }
        }
    }

    @ViewBuilder
    func sortMenuTrigger(title: String, reservedTitle: String) -> some View {
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

        withAnimation(.snappy(duration: 0.18)) {
            focusState.sortMode = nextMode
        }
    }

    func restorePreset() {
        // Preset restore will be implemented with the future preset feature.
    }

    func toggleAdvancedOptions() {
        withAnimation(.spring(duration: 0.2)) {
            isShowingAdvancedOptions.toggle()
        }
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
