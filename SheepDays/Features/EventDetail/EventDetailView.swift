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
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.haptics) private var haptics

    // MARK: - Model
    @Bindable var event: Event

    // MARK: - Queries
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

    // MARK: - UI State
    @State private var errorMessage: String?
    @State private var pendingManagementAction: EventDetailManagementAction?
    @State private var newChecklistItemTitle: String = ""
    @State private var draggedChecklistItemID: UUID?
    @State private var dragTranslationY: CGFloat = 0
    @State private var dragStartFrame: CGRect?
    @State private var dragOrderIDs: [UUID] = []
    @State private var checklistRowFrames: [UUID: CGRect] = [:]
    @State private var checklistScrollFrame: CGRect = .zero
    @State private var focusedChecklistItemID: UUID?
    @State private var isNewChecklistItemFieldFocused: Bool = false

    // MARK: - Callbacks
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
                        memorialSection
                        importanceLevelSection
                        checklistSection()

                        Color.clear.frame(height: bottomContentSpacerHeight)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 20)
                }
                .background(
                    SDRoundedBackground(topLeading: 30, topTrailing: 30, bottomLeading: 15, bottomTrailing: 15, cornerStyle: .continuous, color: Color(.systemBackground))
                )
                .clipShape(
                    SDRoundedCornersShape(topLeading: 30, topTrailing: 30, bottomLeading: 15, bottomTrailing: 15, style: .continuous)
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
//                .ignoresSafeArea(.keyboard, edges: .bottom)
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

// MARK: - Preview
#Preview("Home Sheet") {
    EventDetailSheetPreviewHost(event: eventDetailPreviewEvent)
        .modelContainer(eventDetailPreviewContainer)
}

private extension EventDetailView {
    // MARK: - Form Sections
    var titleSection: some View {
        EventDetailHeaderSection(
            iconSystemName: event.iconSystemName,
            accentColor: eventAccentColor,
            remainingDaysText: remainingDaysText,
            title: titleBinding,
            onIconTap: presentSymbolPicker
        )
    }

    var notebookAndTagsSection: some View {
        EventDetailNotebookTagsSection(
            notebooks: notebooks,
            selectedNotebook: event.notebook,
            tags: event.tags,
            onMoveToNotebook: { notebook in
                moveToNotebook(notebook)
            },
            onRequestTagList: presentTagList
        )
    }

    var noteSection: some View {
        EventDetailNoteSection(note: noteBinding)
    }

    var dateSection: some View {
        EventDetailDateSection(date: dateBinding, range: eventDateRange)
    }

    var showOnHomeSection: some View {
        EventDetailToggleRow(
            title: "显示在首页",
            systemImage: "star",
            isOn: showOnHomeBinding,
            accentColor: eventAccentColor
        )
    }

    var pinToTopSection: some View {
        EventDetailToggleRow(
            title: "置顶",
            systemImage: "pin",
            isOn: pinToTopBinding,
            accentColor: eventAccentColor
        )
    }

    var memorialSection: some View {
        EventDetailToggleRow(
            title: "纪念日",
            systemImage: "calendar.badge.clock",
            isOn: isMemorialBinding,
            accentColor: eventAccentColor
        )
    }

    var importanceLevelSection: some View {
        EventDetailImportanceSection(
            importanceLevel: event.importanceLevel,
            levelText: importanceLevelText,
            accentColor: eventAccentColor,
            onSetLevel: setImportanceLevel(_:)
        )
    }

    // MARK: - Checklist Section
    func checklistSection() -> some View {
        VStack {
            HStack {
                EventDetailSectionTitle(title: "检查清单", systemImage: "checklist")

                Spacer()

                if event.hasChecklistItems {
                    Text("\(event.completedChecklistItemCount)/\(event.checklistItemCount)")
                        .contentTransition(.numericText())
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }

            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    checklistCreateRow

                    ForEach(orderedChecklistItems) { item in
                        checklistItemRow(for: item)
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

    // MARK: - Checklist Rows
    var checklistCreateRow: some View {
        HStack {
            Image(systemName: "circle")
                .foregroundStyle(Color(.tertiaryLabel))
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .contentTransition(.symbolEffect)

            ChecklistCreateTextField(
                text: $newChecklistItemTitle,
                placeholder: "新的检查事项",
                isFocused: isNewChecklistItemFieldFocused,
                onSubmit: createChecklistItem,
                onBeginEditing: {
                    if focusedChecklistItemID != nil {
                        focusedChecklistItemID = nil
                    }

                    if !isNewChecklistItemFieldFocused {
                        isNewChecklistItemFieldFocused = true
                    }
                },
                onEndEditing: {
                    if isNewChecklistItemFieldFocused {
                        isNewChecklistItemFieldFocused = false
                    }
                }
            )
            .frame(minHeight: 24)

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 7)
        .background(
            checklistRowBackground
        )
        .id(ChecklistScrollTarget.newItem)
    }

    func checklistItemRow(for item: ChecklistItem) -> some View {
        let isDragging = draggedChecklistItemID == item.id

        return ZStack {
            checklistItemRowContent(for: item, mode: .normal)
                .opacity(isDragging ? 0 : 1)

            if isDragging {
                checklistPlaceholderRow
                    .allowsHitTesting(false)
            }
        }
        .id(ChecklistScrollTarget.item(item.id))
        .background(checklistRowFrameReader(for: item.id))
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
    }

    func checklistItemRowContent(
        for item: ChecklistItem,
        mode: ChecklistRowMode
    ) -> some View {
        HStack {
            Button {
                toggleChecklistItem(item)
            } label: {
                checklistStatusIcon(for: item)
            }
            .buttonStyle(.plain)
            .disabled(mode != .normal)

            if mode == .normal && !item.isCompleted {
                ChecklistTitleTextField(
                    text: checklistTitleBinding(for: item),
                    placeholder: "检查事项",
                    isFocused: focusedChecklistItemID == item.id,
                    onEmptyBackspace: {
                        deleteChecklistItem(item)
                    },
                    onBeginEditing: {
                        if focusedChecklistItemID != item.id {
                            focusedChecklistItemID = item.id
                        }
                    },
                    onEndEditing: {
                        if focusedChecklistItemID == item.id {
                            focusedChecklistItemID = nil
                        }
                    }
                )
                .frame(minHeight: 24)
            } else {
                checklistItemTitleText(for: item)
            }

            Spacer()

            Image(systemName: "line.3.horizontal")
                .fontDesign(.rounded)
                .foregroundStyle(Color(.tertiaryLabel))
                .frame(width: 40, height: 32)
                .contentShape(Rectangle())
                .gesture(checklistDragGesture(for: item))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 7)
        .opacity(item.isCompleted ? 0.6 : 1)
    }

    // MARK: - Checklist Supporting Views
    func checklistItemTitleText(for item: ChecklistItem) -> some View {
        Text(item.title.isEmpty ? "检查事项" : item.title)
            .lineLimit(1)
            .strikethrough(item.isCompleted, color: Color(.tertiaryLabel))
            .frame(maxWidth: .infinity, alignment: .leading)
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
                    .fill(.white)
                    .overlay {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .foregroundStyle(eventAccentColor.opacity(0.2))
                    }
                    
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(eventAccentColor, lineWidth: 2)
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
            .foregroundStyle(eventAccentColor)
            .font(.system(size: 20, weight: .medium, design: .rounded))
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

    // MARK: - Controls
    var controls: some View {
        EventDetailControls(
            onClose: onClose,
            onArchive: { pendingManagementAction = .archive },
            onDelete: { pendingManagementAction = .delete }
        )
    }

    // MARK: - Display Values
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

    var importanceLevelText: String {
        "\(event.importanceLevel)/5"
    }

    var eventDateRange: ClosedRange<Date> {
        Date.distantPast...Date.distantFuture
    }

    // MARK: - Layout Values
    var isChecklistInputFocused: Bool {
        isNewChecklistItemFieldFocused || focusedChecklistItemID != nil
    }

    var bottomContentSpacerHeight: CGFloat {
        isChecklistInputFocused ? 320 : 50
    }

    // MARK: - Checklist Values
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

    // MARK: - Presentation Bindings
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

    // MARK: - Field Bindings
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

    var isMemorialBinding: Binding<Bool> {
        Binding(
            get: { event.isMemorial },
            set: { newValue in
                event.isMemorial = newValue
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

    // MARK: - Symbol and Tag Actions
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

    // MARK: - Checklist Dragging
    func checklistDragGesture(for item: ChecklistItem) -> some Gesture {
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
                    updateChecklistDragOrder(for: item.id)
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

    func updateChecklistDragOrder(for draggedID: UUID) {
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
            return
        }

        withAnimation(.snappy(duration: 0.18)) {
            dragOrderIDs = nextOrder
        }
        haptics.play(.selectionStep)
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

    // MARK: - Checklist Focus and Scrolling
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

    // MARK: - Checklist Mutations
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
        
        withAnimation(.snappy(duration: 0.22)) {
            event.checklistItems.append(item)
        }
        
        newChecklistItemTitle = ""
        persistChanges()
    }

    func toggleChecklistItem(_ item: ChecklistItem) {
        haptics.play(.openDetailTap)
        
        withAnimation {
            item.isCompleted.toggle()
        }
        item.updatedAt = .now

        if item.isCompleted, focusedChecklistItemID == item.id {
            focusedChecklistItemID = nil
        }

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
        moveChecklistFocusAfterDeleting(item)

        withAnimation(.snappy(duration: 0.18)) {
            event.checklistItems.removeAll { $0.id == item.id }
        }

        modelContext.delete(item)
        normalizeChecklistOrder(sortedChecklistItems)
        persistChanges()
    }

    func moveChecklistFocusAfterDeleting(_ item: ChecklistItem) {
        if let previousEditableItemID = previousEditableChecklistItemID(before: item) {
            focusedChecklistItemID = previousEditableItemID
            isNewChecklistItemFieldFocused = false
        } else {
            focusedChecklistItemID = nil
            isNewChecklistItemFieldFocused = true
        }
    }

    func previousEditableChecklistItemID(before item: ChecklistItem) -> UUID? {
        guard let currentIndex = orderedChecklistItems.firstIndex(where: { $0.id == item.id }) else {
            return nil
        }

        return orderedChecklistItems[..<currentIndex]
            .reversed()
            .first { !$0.isCompleted }?
            .id
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

    // MARK: - Event Management Actions
    private func performManagementAction(_ action: EventDetailManagementAction) {
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

    // MARK: - Persistence
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
