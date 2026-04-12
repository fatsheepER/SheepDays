//
//  FocusSheetView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import SwiftUI
import SwiftData

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
                color: Color(.secondarySystemBackground)
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
            Text("timeRange")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            SDRoundedBackground(topLeading: 10, topTrailing: 10, bottomLeading: 10, bottomTrailing: 10, cornerStyle: .continuous, color: Color(.secondarySystemBackground))
        )
    }

    var sortMode: some View {
        VStack {
            Text("sortMode")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            SDRoundedBackground(topLeading: 10, topTrailing: 10, bottomLeading: 10, bottomTrailing: 10, cornerStyle: .continuous, color: Color(.secondarySystemBackground))
        )
    }

    var groupingMode: some View {
        VStack {
            Text("groupingMode")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            SDRoundedBackground(topLeading: 10, topTrailing: 10, bottomLeading: 10, bottomTrailing: 10, cornerStyle: .continuous, color: Color(.secondarySystemBackground))
        )
    }

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
                    iconSystemName: "arrow.uturn.backward",
                    title: "还原",
                    placement: .left,
                    style: .plain
                )
            }
            .buttonStyle(.plain)

            Button(action: toggleAdvancedOptions) {
                SDSheetActionButton(
                    iconSystemName: isShowingAdvancedOptions ? "square.grid.2x2" : "ellipsis",
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

    func restorePreset() {
        // Preset restore will be implemented with the future preset feature.
    }

    func toggleAdvancedOptions() {
        withAnimation(.spring(duration: 0.2)) {
            isShowingAdvancedOptions.toggle()
        }
    }
}

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
