//
//  EventDetailView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/6.
//

import SwiftUI
import SwiftData
import UIKit

struct EventDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.haptics) private var haptics
    @Bindable var event: Event

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
    private var allTags: [Tag]

    @State private var errorMessage: String?
    @State private var pendingManagementAction: PendingManagementAction?
    @State private var newChecklistItemTitle: String = ""
    @State private var draggedChecklistItemID: UUID?
    @State private var dragTranslationY: CGFloat = 0
    @State private var dragStartFrame: CGRect?
    @State private var dragOrderIDs: [UUID] = []
    @State private var checklistRowFrames: [UUID: CGRect] = [:]
    @State private var checklistScrollFrame: CGRect = .zero
    @State private var focusedChecklistItemID: UUID?
    @FocusState private var isNewChecklistItemFieldFocused: Bool

    var onClose: () -> Void = {}
    var onEventUpdated: () -> Void = {}
    var onRequestSymbolPicker: (SymbolPickerPresentation) -> Void = { _ in }
    var onRequestTagList: (TagListPresentation) -> Void = { _ in }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 10) {
            ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 15) {
                        titleSection
                        notebookAndTagsSection
                        noteSection
                        dateSection
                        showOnHomeSection
                        pinToTopSection
                        importanceLevelSection
                        checklistSection(scrollProxy: scrollProxy)

                        Color.clear.frame(height: bottomContentSpacerHeight)
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 5)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .foregroundStyle(Color(.quaternarySystemFill))
                )
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: isNewChecklistItemFieldFocused) { _, isFocused in
                    if isFocused {
                        focusedChecklistItemID = nil
                        scrollToChecklistInput(.newItem, with: scrollProxy)
                    }
                }
                .onChange(of: focusedChecklistItemID) { _, itemID in
                    if let itemID {
                        isNewChecklistItemFieldFocused = false
                        scrollToChecklistInput(.item(itemID), with: scrollProxy)
                    }
                }
            }

            controls

            if isChecklistInputFocused {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

        .alert(
            "操作失败",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        errorMessage = nil
                    }
                }
            )
        ) {
            Button("确定", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "未知错误")
        }
        .alert(
            pendingManagementAction?.title ?? "管理事件",
            isPresented: pendingManagementActionIsPresented,
            presenting: pendingManagementAction
        ) { action in
            Button(action.confirmButtonTitle, role: .destructive) {
                performManagementAction(action)
            }
            Button("取消", role: .cancel) {
                pendingManagementAction = nil
            }
        } message: { action in
            Text(action.message)
        }
    }
}

private extension EventDetailView {
    // MARK: - Subviews
    var titleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button {
                    presentSymbolPicker()
                } label: {
                    Image(systemName: event.iconSystemName ?? "calendar")
                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                        .foregroundStyle(eventAccentColor)
                }
                .buttonStyle(.plain)
                .frame(height: 50)

                Spacer()

                Text(remainingDaysText)
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(eventAccentColor)
            }

            TextField("请输入事件名称", text: titleBinding)
                .textFieldStyle(.plain)
                .font(.system(size: 25, weight: .semibold, design: .rounded))
        }
    }

    var notebookAndTagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Menu {
                        if notebooks.isEmpty {
                            Text("暂无事件本")
                        } else {
                            Section("选择事件本") {
                                ForEach(notebooks) { notebook in
                                    Button {
                                        moveToNotebook(notebook)
                                    } label: {
                                        notebookMenuLabel(
                                            for: notebook,
                                            isSelected: notebook.id == event.notebook?.id
                                        )
                                    }
                                }
                            }
                        }
                    } label: {
                        SDNotebookBadge(notebook: event.notebook)
                            .frame(height: 40)
                    }
                    .buttonStyle(.plain)

                    ForEach(event.tags.sorted(by: { $0.name.localizedCompare($1.name) == .orderedAscending })) { tag in
                        Button {
                            presentTagList()
                        } label: {
                            SDTagBadge(tag: tag)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        presentTagList()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(.secondaryLabel))
                            .padding(10)
                            .background(
                                Capsule()
                                    .foregroundStyle(Color(.tertiarySystemFill))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var noteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("备注", "note.text")

            TextEditor(text: noteBinding)
                .textEditorStyle(.plain)
                .frame(minHeight: 80)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                )
        }
    }

    var dateSection: some View {
        HStack {
            sectionTitle("日期", "calendar")

            Spacer()

            DatePicker(
                "事件日期",
                selection: dateBinding,
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)
            .labelsHidden()
        }
    }

    var showOnHomeSection: some View {
        HStack {
            sectionTitle("显示在首页", "star")

            Spacer()

            Toggle("", isOn: showOnHomeBinding)
                .tint(.accent)
        }
    }

    var pinToTopSection: some View {
        HStack {
            sectionTitle("置顶", "pin")

            Spacer()

            Toggle("", isOn: pinToTopBinding)
                .tint(.accent)
        }
    }

    var importanceLevelSection: some View {
        VStack {
            // title
            HStack {
                sectionTitle("重要性", "flag")

                Spacer()

                Text(importanceLevelText)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(.tertiaryLabel))
            }

            // indicator
            HStack {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        setImportanceLevel(level)
                    } label: {
                        Capsule()
                            .frame(height: 10)
                            .foregroundStyle(
                                event.importanceLevel >= level
                                ? eventAccentColor
                                : Color(.tertiarySystemFill)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical)
            .padding(.horizontal)
        }
    }

    func checklistSection(scrollProxy: ScrollViewProxy) -> some View {
        VStack {
            HStack {
                sectionTitle("检查清单", "checklist")

                Spacer()

                if event.hasChecklistItems {
                    Text("\(event.completedChecklistItemCount)/\(event.checklistItemCount)")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }

            ZStack(alignment: .topLeading) {
                VStack(spacing: 3) {
                    checklistCreateRow

                    ForEach(orderedChecklistItems) { item in
                        checklistItemRow(for: item, scrollProxy: scrollProxy)
                    }
                }
                .background(checklistScrollFrameReader)

                if let draggedItem {
                    checklistFloatingRow(for: draggedItem)
                }
            }
            .coordinateSpace(name: ChecklistCoordinateSpace.name)
            .onPreferenceChange(ChecklistRowFramePreferenceKey.self) { frames in
                checklistRowFrames = frames
            }
            .onPreferenceChange(ChecklistScrollFramePreferenceKey.self) { frame in
                checklistScrollFrame = frame
            }
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(Color(.secondaryLabel))
        }
    }

    var checklistCreateRow: some View {
        HStack {
            Button {
                createChecklistItem()
            } label: {
                Image(systemName: "circle.dashed")
                    .foregroundStyle(Color(.tertiaryLabel))
                    .fontDesign(.rounded)
                    .contentTransition(.symbolEffect)
            }
            .buttonStyle(.plain)

            TextField("新的检查事项", text: $newChecklistItemTitle)
                .textFieldStyle(.plain)
                .submitLabel(.done)
                .focused($isNewChecklistItemFieldFocused)
                .onSubmit(createChecklistItem)

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 7)
        .background(
            checklistRowBackground
        )
        .id(ChecklistScrollTarget.newItem)
    }

    func checklistItemRow(for item: ChecklistItem, scrollProxy: ScrollViewProxy) -> some View {
        let isDragging = draggedChecklistItemID == item.id

        return ZStack {
            checklistItemRowContent(for: item, mode: .normal, scrollProxy: scrollProxy)
                .opacity(isDragging ? 0 : 1)

            if isDragging {
                checklistPlaceholderRow
                    .allowsHitTesting(false)
            }
        }
        .id(ChecklistScrollTarget.item(item.id))
        .background(checklistRowFrameReader(for: item.id))
    }

    func checklistItemRowContent(
        for item: ChecklistItem,
        mode: ChecklistRowMode,
        scrollProxy: ScrollViewProxy? = nil
    ) -> some View {
        HStack {
            Button {
                toggleChecklistItem(item)
            } label: {
                checklistStatusIcon(for: item)
            }
            .buttonStyle(.plain)
            .disabled(mode != .normal)

            if mode == .normal {
                ChecklistTitleTextField(
                    text: checklistTitleBinding(for: item),
                    placeholder: "检查事项",
                    onEmptyBackspace: {
                        deleteChecklistItem(item)
                    },
                    onBeginEditing: {
                        focusedChecklistItemID = item.id
                    },
                    onEndEditing: {
                        if focusedChecklistItemID == item.id {
                            focusedChecklistItemID = nil
                        }
                    }
                )
                .frame(minHeight: 24)
            } else {
                Text(item.title.isEmpty ? "检查事项" : item.title)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()

            Image(systemName: "line.3.horizontal")
                .fontDesign(.rounded)
                .foregroundStyle(Color(.tertiaryLabel))
                .frame(width: 40, height: 32)
                .contentShape(Rectangle())
                .gesture(checklistDragGesture(for: item, scrollProxy: scrollProxy))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 7)
    }

    var checklistPlaceholderRow: some View {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
            .foregroundStyle(Color(.tertiarySystemFill))
            .frame(height: checklistRowHeight)
    }

    func checklistFloatingRow(for item: ChecklistItem) -> some View {
        checklistItemRowContent(for: item, mode: .floating)
            .frame(width: checklistFloatingRowFrame(for: item).width)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .foregroundStyle(eventAccentColor.opacity(0.22))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(eventAccentColor.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.14), radius: 10, y: 5)
            .offset(
                x: checklistFloatingRowFrame(for: item).minX + 10,
                y: checklistFloatingRowFrame(for: item).minY + dragTranslationY
            )
            .zIndex(10)
            .allowsHitTesting(false)
    }

    func checklistStatusIcon(for item: ChecklistItem) -> some View {
        Image(systemName: item.isCompleted ? "checkmark.circle" : "circle")
            .foregroundStyle(.accent)
            .fontDesign(.rounded)
    }

    var checklistRowBackground: some View {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
            .foregroundStyle(Color(.tertiarySystemFill))
    }

    func checklistFloatingRowFrame(for item: ChecklistItem) -> CGRect {
        dragStartFrame ?? checklistRowFrames[item.id] ?? CGRect(
            x: 0,
            y: 0,
            width: max(checklistScrollFrame.width, 260),
            height: checklistRowHeight
        )
    }

    var checklistScrollFrameReader: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: ChecklistScrollFramePreferenceKey.self,
                value: proxy.frame(in: .named(ChecklistCoordinateSpace.name))
            )
        }
    }

    func checklistRowFrameReader(for itemID: UUID) -> some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: ChecklistRowFramePreferenceKey.self,
                value: [itemID: proxy.frame(in: .named(ChecklistCoordinateSpace.name))]
            )
        }
    }

    var controls: some View {
        HStack(spacing: 10) {
            // back
            Button {
                onClose()
            } label: {
                SDSheetActionButton(iconSystemName: "arrow.left", title: "返回", placement: .left, style: .secondary)
            }
            .buttonStyle(.plain)

            Menu {
                Button {
                    pendingManagementAction = .archive
                } label: {
                    Label("归档", systemImage: "tray")
                }

                Button(role: .destructive) {
                    pendingManagementAction = .delete
                } label: {
                    Label("删除", systemImage: "trash")
                }
            } label: {
                SDSheetActionButton(iconSystemName: "tray", title: "管理", placement: .right, style: .destructive)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Computed variables
    var eventAccentColor: Color {
        if let colorHex = event.notebook?.colorHex,
           let color = Color(hex: colorHex) {
            return color
        }

        return .accent
    }

    var remainingDayCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let target = calendar.startOfDay(for: event.targetDate)
        return calendar.dateComponents([.day], from: today, to: target).day ?? 0
    }

    var remainingDaysText: String {
        switch remainingDayCount {
        case 0:
            return "今天"
        case let count where count > 0:
            return "还有 \(count) 天"
        default:
            return "已过 \(abs(remainingDayCount)) 天"
        }
    }

    var trimmedTitle: String {
        event.title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var importanceLevelText: String {
        "\(event.importanceLevel)/5"
    }

    var isChecklistInputFocused: Bool {
        isNewChecklistItemFieldFocused || focusedChecklistItemID != nil
    }

    var bottomContentSpacerHeight: CGFloat {
        isChecklistInputFocused ? 320 : 50
    }

    var orderedChecklistItems: [ChecklistItem] {
        let sortedItems = sortedChecklistItems
        let itemsByID = Dictionary(uniqueKeysWithValues: sortedItems.map { ($0.id, $0) })
        let orderedItems = dragOrderIDs.compactMap { itemsByID[$0] }
        let missingItems = sortedItems.filter { !dragOrderIDs.contains($0.id) }
        return dragOrderIDs.isEmpty ? sortedItems : orderedItems + missingItems
    }

    var draggedItem: ChecklistItem? {
        guard let draggedChecklistItemID else {
            return nil
        }

        return sortedChecklistItems.first { $0.id == draggedChecklistItemID }
    }

    var sortedChecklistItems: [ChecklistItem] {
        event.checklistItems.sorted {
            if $0.sortIndex != $1.sortIndex {
                return $0.sortIndex > $1.sortIndex
            }

            return $0.createdAt > $1.createdAt
        }
    }

    var checklistRowHeight: CGFloat {
        48
    }

    var pendingManagementActionIsPresented: Binding<Bool> {
        Binding(
            get: { pendingManagementAction != nil },
            set: { isPresented in
                if !isPresented {
                    pendingManagementAction = nil
                }
            }
        )
    }

    private enum PendingManagementAction: String, Identifiable {
        case archive
        case delete

        var id: String { rawValue }

        var title: String {
            switch self {
            case .archive:
                return "归档事件"
            case .delete:
                return "删除事件"
            }
        }

        var message: String {
            switch self {
            case .archive:
                return "归档后，这个事件会从当前列表中隐藏。"
            case .delete:
                return "删除后无法恢复。"
            }
        }

        var confirmButtonTitle: String {
            switch self {
            case .archive:
                return "确认归档"
            case .delete:
                return "确认删除"
            }
        }
    }

    // MARK: - Bindings
    var titleBinding: Binding<String> {
        Binding(
            get: { event.title },
            set: { newValue in
                event.title = newValue
                persistChanges()
            }
        )
    }

    var dateBinding: Binding<Date> {
        Binding(
            get: { event.targetDate },
            set: { newValue in
                event.targetDate = Calendar.current.startOfDay(for: newValue)
                persistChanges()
            }
        )
    }

    var showOnHomeBinding: Binding<Bool> {
        Binding(
            get: { event.showOnHome },
            set: { newValue in
                event.showOnHome = newValue
                persistChanges()
            }
        )
    }

    var pinToTopBinding: Binding<Bool> {
        Binding(
            get: { event.pinToTop },
            set: { newValue in
                event.pinToTop = newValue
                persistChanges()
            }
        )
    }

    var notebookSelection: Binding<UUID?> {
        Binding(
            get: { event.notebook?.id },
            set: { notebookID in
                event.notebook = notebooks.first(where: { $0.id == notebookID })
                persistChanges()
            }
        )
    }

    var noteBinding: Binding<String> {
        Binding(
            get: { event.note ?? "" },
            set: { newValue in
                let trimmedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                event.note = trimmedValue.isEmpty ? nil : newValue
                persistChanges()
            }
        )
    }

    func checklistTitleBinding(for item: ChecklistItem) -> Binding<String> {
        Binding(
            get: { item.title },
            set: { newValue in
                updateChecklistItemTitle(item, title: newValue)
            }
        )
    }

    @ViewBuilder
    func sectionTitle(_ title: String, _ imageName: String) -> some View {
        HStack(alignment: .firstTextBaseline,spacing: 5) {
            Image(systemName: imageName)
                .font(.system(size: 18, weight: .medium))

            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(.secondaryLabel))
        }
        .frame(height: 35)
        .foregroundStyle(Color(.secondaryLabel))
    }

    func notebookMenuLabel(for notebook: Notebook, isSelected: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: notebook.iconSystemName ?? "book.closed")
                .foregroundStyle(notebook.tintColor)
            Text(notebook.name)

            if isSelected {
                Spacer()
                Image(systemName: "checkmark")
                    .foregroundStyle(Color(.secondaryLabel))
            }
        }
    }

    // MARK: - Functions
    func applySymbolSelection(_ systemName: String?) {
        event.iconSystemName = systemName
        persistChanges()
    }

    func presentSymbolPicker() {
        onRequestSymbolPicker(
            SymbolPickerPresentation(
                title: "选择事件图标",
                sections: SFSymbolLibrary.generalSections,
                selectedSystemName: event.iconSystemName,
                tintColor: eventAccentColor,
                onSelect: applySymbolSelection(_:)
            )
        )
    }

    func presentTagList() {
        onRequestTagList(
            TagListPresentation(
                mode: .selection(
                    selectedTagIDs: Set(event.tags.map(\.id)),
                    onSelectionChange: applyTagSelection(_:)
                )
            )
        )
    }

    func applyTagSelection(_ selectedTagIDs: Set<UUID>) {
        let currentTagIDs = Set(event.tags.map(\.id))
        guard currentTagIDs != selectedTagIDs else {
            return
        }

        event.tags = allTags.filter { selectedTagIDs.contains($0.id) }
        persistChanges()
    }

    func moveToNotebook(_ notebook: Notebook?) {
        event.notebook = notebook
        persistChanges()
    }

    func checklistDragGesture(for item: ChecklistItem, scrollProxy: ScrollViewProxy?) -> some Gesture {
        LongPressGesture(minimumDuration: 0.35, maximumDistance: 12)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named(ChecklistCoordinateSpace.name)))
            .onChanged { value in
                switch value {
                case .second(true, let dragValue):
                    if draggedChecklistItemID != item.id {
                        beginChecklistDrag(for: item)
                    }

                    guard let dragValue else {
                        return
                    }

                    dragTranslationY = dragValue.translation.height
                    updateChecklistDragOrder(for: item.id, scrollProxy: scrollProxy)
                default:
                    break
                }
            }
            .onEnded { _ in
                endChecklistDrag()
            }
    }

    func beginChecklistDrag(for item: ChecklistItem) {
        guard draggedChecklistItemID != item.id else {
            return
        }

        endChecklistEditing()
        draggedChecklistItemID = item.id
        dragTranslationY = 0
        dragStartFrame = checklistRowFrames[item.id]
        dragOrderIDs = orderedChecklistItems.map(\.id)
        haptics.play(.selectionStep)
    }

    func updateChecklistDragOrder(for draggedID: UUID, scrollProxy: ScrollViewProxy?) {
        let currentOrder = dragOrderIDs.isEmpty ? sortedChecklistItems.map(\.id) : dragOrderIDs
        guard let draggedFrame = dragStartFrame ?? checklistRowFrames[draggedID] else {
            return
        }

        let floatingMidY = draggedFrame.midY + dragTranslationY
        var nextOrder = currentOrder.filter { $0 != draggedID }
        let targetIndex = nextOrder.filter { id in
            guard let frame = checklistRowFrames[id] else {
                return false
            }

            return frame.midY < floatingMidY
        }.count

        nextOrder.insert(draggedID, at: min(targetIndex, nextOrder.count))

        guard nextOrder != currentOrder else {
            autoScrollChecklistIfNeeded(for: draggedID, scrollProxy: scrollProxy)
            return
        }

        withAnimation(.snappy(duration: 0.18)) {
            dragOrderIDs = nextOrder
        }
        haptics.play(.selectionStep)
        autoScrollChecklistIfNeeded(for: draggedID, scrollProxy: scrollProxy)
    }

    func autoScrollChecklistIfNeeded(for draggedID: UUID, scrollProxy: ScrollViewProxy?) {
        guard let scrollProxy,
              let currentIndex = dragOrderIDs.firstIndex(of: draggedID) else {
            return
        }

        if dragTranslationY < -90, currentIndex > 0 {
            let targetID = dragOrderIDs[currentIndex - 1]
            withAnimation(.linear(duration: 0.18)) {
                scrollProxy.scrollTo(ChecklistScrollTarget.item(targetID), anchor: .top)
            }
        } else if dragTranslationY > 90, currentIndex < dragOrderIDs.count - 1 {
            let targetID = dragOrderIDs[currentIndex + 1]
            withAnimation(.linear(duration: 0.18)) {
                scrollProxy.scrollTo(ChecklistScrollTarget.item(targetID), anchor: .bottom)
            }
        }
    }

    func endChecklistDrag() {
        defer {
            draggedChecklistItemID = nil
            dragTranslationY = 0
            dragStartFrame = nil
            dragOrderIDs = []
        }

        let originalOrderIDs = sortedChecklistItems.map(\.id)
        guard !dragOrderIDs.isEmpty,
              dragOrderIDs != originalOrderIDs else {
            return
        }

        let itemsByID = Dictionary(uniqueKeysWithValues: sortedChecklistItems.map { ($0.id, $0) })
        let orderedItems = dragOrderIDs.compactMap { itemsByID[$0] }
        normalizeChecklistOrder(orderedItems)
        persistChanges()
    }

    func endChecklistEditing() {
        isNewChecklistItemFieldFocused = false
        focusedChecklistItemID = nil
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    func scrollToChecklistInput(_ target: ChecklistScrollTarget, with proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.snappy(duration: 0.25)) {
                proxy.scrollTo(target, anchor: .center)
            }
        }
    }

    func createChecklistItem() {
        let title = newChecklistItemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            return
        }

        let item = ChecklistItem(
            title: title,
            sortIndex: (sortedChecklistItems.map(\.sortIndex).max() ?? 0) + 1
        )

        modelContext.insert(item)
        event.checklistItems.append(item)
        newChecklistItemTitle = ""
        keepNewChecklistItemFieldFocused()
        persistChanges()
    }

    func keepNewChecklistItemFieldFocused() {
        DispatchQueue.main.async {
            isNewChecklistItemFieldFocused = true
        }
    }

    func toggleChecklistItem(_ item: ChecklistItem) {
        item.isCompleted.toggle()
        item.updatedAt = .now
        persistChanges()
    }

    func updateChecklistItemTitle(_ item: ChecklistItem, title: String) {
        guard item.title != title else {
            return
        }

        item.title = title
        item.updatedAt = .now
        persistChanges()
    }

    func deleteChecklistItem(_ item: ChecklistItem) {
        event.checklistItems.removeAll { $0.id == item.id }
        modelContext.delete(item)
        normalizeChecklistOrder(sortedChecklistItems)
        persistChanges()
    }

    func normalizeChecklistOrder(_ items: [ChecklistItem]) {
        let count = items.count

        for (offset, item) in items.enumerated() {
            let newSortIndex = count - offset

            if item.sortIndex != newSortIndex {
                item.sortIndex = newSortIndex
                item.updatedAt = .now
            }
        }
    }

    private func performManagementAction(_ action: PendingManagementAction) {
        switch action {
        case .archive:
            archiveEvent()
        case .delete:
            deleteEvent()
        }
    }

    func archiveEvent() {
        event.isArchived = true
        event.archivedAt = .now

        if persistChanges() {
            onClose()
        }
    }

    func deleteEvent() {
        modelContext.delete(event)

        do {
            try modelContext.save()
            onEventUpdated()
            onClose()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }

    func setImportanceLevel(_ level: Int) {
        if level == 1, event.importanceLevel == 1 {
            haptics.play(.error)
            event.importanceLevel = 0
        } else {
            haptics.play(.selectionStep)
            event.importanceLevel = level
        }

        persistChanges()
    }

    @discardableResult
    func persistChanges() -> Bool {
        event.updatedAt = .now

        do {
            try modelContext.save()
            onEventUpdated()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

private enum ChecklistScrollTarget: Hashable {
    case newItem
    case item(UUID)
}

private enum ChecklistRowMode: Equatable {
    case normal
    case floating
}

private enum ChecklistCoordinateSpace {
    static let name = "event-detail-checklist"
}

private struct ChecklistRowFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, newValue in newValue })
    }
}

private struct ChecklistScrollFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

private struct ChecklistTitleTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let onEmptyBackspace: () -> Void
    let onBeginEditing: () -> Void
    let onEndEditing: () -> Void

    func makeUIView(context: Context) -> EmptyBackspaceTextField {
        let textField = EmptyBackspaceTextField()
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.font = .systemFont(ofSize: 18, weight: .medium)
        textField.textColor = .secondaryLabel
        textField.placeholder = placeholder
        textField.returnKeyType = .done
        textField.onEmptyBackspace = context.coordinator.handleEmptyBackspace
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange(_:)),
            for: .editingChanged
        )
        textField.delegate = context.coordinator
        return textField
    }

    func updateUIView(_ uiView: EmptyBackspaceTextField, context: Context) {
        context.coordinator.parent = self

        if uiView.text != text {
            uiView.text = text
        }

        uiView.placeholder = placeholder
        uiView.onEmptyBackspace = context.coordinator.handleEmptyBackspace
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: ChecklistTitleTextField

        init(parent: ChecklistTitleTextField) {
            self.parent = parent
        }

        @objc func textDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onBeginEditing()
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.onEndEditing()
        }

        func handleEmptyBackspace() {
            DispatchQueue.main.async {
                self.parent.onEmptyBackspace()
            }
        }
    }

    final class EmptyBackspaceTextField: UITextField {
        var onEmptyBackspace: (() -> Void)?

        override func deleteBackward() {
            if text?.isEmpty ?? true {
                onEmptyBackspace?()
            } else {
                super.deleteBackward()
            }
        }
    }
}

// MARK: - Preview
#Preview("Home Sheet") {
    EventDetailSheetPreviewHost(event: eventDetailPreviewEvent)
        .modelContainer(eventDetailPreviewContainer)
}

private struct EventDetailSheetPreviewHost: View {
    @Environment(\.haptics) private var haptics
    @StateObject private var overlayCoordinator = AppOverlayCoordinator()
    @State private var isBottomSheetPresented = true
    @State private var selectedSheetDetent: PresentationDetent = .fraction(0.82)

    let event: Event

    var body: some View {
        NavigationStack {
            previewHomeContent
                .safeAreaInset(edge: .bottom) {
                    if isBottomSheetPresented {
                        Color.clear
                            .frame(height: 170)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                .sheet(isPresented: $isBottomSheetPresented) {
                    sheetContainer
                        .ignoresSafeArea()
                }
        }
        .environment(\.appOverlayCoordinator, overlayCoordinator)
        .background(
            AppOverlayWindowPresenter(
                coordinator: overlayCoordinator,
                haptics: haptics,
                modelContainer: eventDetailPreviewContainer
            )
        )
    }

    private var previewHomeContent: some View {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
    }

    private var sheetContainer: some View {
        VStack(spacing: 0) {
            EventDetailView(
                event: event,
                onClose: {},
                onRequestSymbolPicker: presentSymbolPicker(_:),
                onRequestTagList: presentTagList(_:)
            )
            .transition(.opacity)
        }
        .presentationDetents([.fraction(0.82)], selection: $selectedSheetDetent)
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
        .presentationBackgroundInteraction(.enabled)
        .interactiveDismissDisabled()
        .padding(15)
    }

    private func presentSymbolPicker(_ presentation: SymbolPickerPresentation) {
        overlayCoordinator.present(
            .symbolPicker(
                presentation: presentation,
                onDismiss: {}
            )
        )
    }

    private func presentTagList(_ presentation: TagListPresentation) {
        overlayCoordinator.present(
            .tagList(
                presentation: presentation,
                onDismiss: {}
            )
        )
    }
}

private let eventDetailPreviewContainer: ModelContainer = {
    let container = ModelContainerProvider.makePreviewContainer()
    let context = container.mainContext

    let notebooks = [
        Notebook(name: "家庭", colorHex: "FF8A65", iconSystemName: "house.fill"),
        Notebook(name: "工作", colorHex: "5C6BC0", iconSystemName: "briefcase.fill"),
        Notebook(name: "旅行", colorHex: "26A69A", iconSystemName: "airplane"),
        Notebook(name: "学习", colorHex: "7E57C2", iconSystemName: "book.fill")
    ]

    let tags = [
        Tag(name: "健康"),
        Tag(name: "暑假计划")
    ]

    notebooks.forEach(context.insert)
    tags.forEach(context.insert)

    let event = Event(
        title: "Project Launch",
        note: "这一块先放一段预览备注，方便继续调 noteSection。",
        targetDate: Calendar.current.date(byAdding: .day, value: 12, to: .now) ?? .now,
        allDay: true,
        iconSystemName: "flag.fill",
        notebook: notebooks[1],
        tags: tags
    )

    context.insert(event)

    [
        ChecklistItem(title: "还没做好的事情", isCompleted: false, sortIndex: 3),
        ChecklistItem(title: "还没做好的事情", isCompleted: true, sortIndex: 2),
        ChecklistItem(title: "空标题后再退格会删除", isCompleted: false, sortIndex: 1)
    ].forEach { item in
        context.insert(item)
        event.checklistItems.append(item)
    }

    return container
}()

private let eventDetailPreviewEvent: Event = {
    let context = eventDetailPreviewContainer.mainContext
    let descriptor = FetchDescriptor<Event>()
    return (try? context.fetch(descriptor).first) ?? Event(title: "Preview Event", targetDate: .now)
}()
