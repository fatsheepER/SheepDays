//
//  EventDetailView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/6.
//

import SwiftUI
import SwiftData
import UIKit
import UniformTypeIdentifiers

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

    var onClose: () -> Void = {}
    var onEventUpdated: () -> Void = {}
    var onRequestSymbolPicker: (SymbolPickerPresentation) -> Void = { _ in }
    var onRequestTagList: (TagListPresentation) -> Void = { _ in }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 10) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 15) {
                    titleSection
                    notebookAndTagsSection
                    noteSection
                    dateSection
                    showOnHomeSection
                    pinToTopSection
                    importanceLevelSection
                    checklistSection

                    Color.clear.frame(height: 50)
                }
                .padding(.top, 24)
                .padding(.horizontal, 5)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .foregroundStyle(Color(.quaternarySystemFill))
            )

            controls
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

    var checklistSection: some View {
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

            VStack(spacing: 3) {
                checklistCreateRow

                ForEach(sortedChecklistItems) { item in
                    checklistItemRow(for: item)
                }

                if sortedChecklistItems.count > 1 {
                    checklistBottomDropTarget
                }
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
                .onSubmit(createChecklistItem)

            Spacer()

            Image(systemName: "line.3.horizontal")
                .fontDesign(.rounded)
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 7)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .foregroundStyle(Color(.tertiarySystemFill))
        )
    }

    func checklistItemRow(for item: ChecklistItem) -> some View {
        HStack {
            Button {
                toggleChecklistItem(item)
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(.accent)
                    .fontDesign(.rounded)
                    .contentTransition(.symbolEffect)
            }
            .buttonStyle(.plain)

            ChecklistTitleTextField(
                text: checklistTitleBinding(for: item),
                placeholder: "检查事项",
                onEmptyBackspace: {
                    deleteChecklistItem(item)
                }
            )
            .frame(minHeight: 24)

            Spacer()

            Image(systemName: "line.3.horizontal")
                .fontDesign(.rounded)
                .foregroundStyle(Color(.tertiaryLabel))
                .contentShape(Rectangle())
                .onDrag {
                    draggedChecklistItemID = item.id
                    return NSItemProvider(object: item.id.uuidString as NSString)
                }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 7)
        .onDrop(
            of: [UTType.text],
            delegate: ChecklistItemDropDelegate(
                itemID: item.id,
                draggedItemID: $draggedChecklistItemID,
                moveItem: moveChecklistItem,
                finalize: finalizeChecklistReorder
            )
        )
    }

    var checklistBottomDropTarget: some View {
        Color.clear
            .frame(height: 10)
            .onDrop(of: [UTType.text], isTargeted: nil) { _ in
                guard let draggedChecklistItemID else {
                    return false
                }

                moveChecklistItemToBottom(draggedChecklistItemID)
                finalizeChecklistReorder()
                return true
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

    var sortedChecklistItems: [ChecklistItem] {
        event.checklistItems.sorted {
            if $0.sortIndex != $1.sortIndex {
                return $0.sortIndex > $1.sortIndex
            }

            return $0.createdAt > $1.createdAt
        }
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
        persistChanges()
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

    func moveChecklistItem(_ draggedID: UUID, _ targetID: UUID) {
        guard draggedID != targetID else {
            return
        }

        var items = sortedChecklistItems
        guard let sourceIndex = items.firstIndex(where: { $0.id == draggedID }),
              let targetIndex = items.firstIndex(where: { $0.id == targetID }) else {
            return
        }

        let movedItem = items.remove(at: sourceIndex)
        let insertionIndex = sourceIndex < targetIndex ? targetIndex - 1 : targetIndex
        items.insert(movedItem, at: insertionIndex)
        normalizeChecklistOrder(items)
    }

    func moveChecklistItemToBottom(_ draggedID: UUID) {
        var items = sortedChecklistItems
        guard let sourceIndex = items.firstIndex(where: { $0.id == draggedID }),
              sourceIndex != items.count - 1 else {
            return
        }

        let movedItem = items.remove(at: sourceIndex)
        items.append(movedItem)
        normalizeChecklistOrder(items)
    }

    func finalizeChecklistReorder() {
        draggedChecklistItemID = nil
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

private struct ChecklistItemDropDelegate: DropDelegate {
    let itemID: UUID
    @Binding var draggedItemID: UUID?
    let moveItem: (UUID, UUID) -> Void
    let finalize: () -> Void

    func dropEntered(info: DropInfo) {
        guard let draggedItemID, draggedItemID != itemID else {
            return
        }

        moveItem(draggedItemID, itemID)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        finalize()
        return true
    }
}

private struct ChecklistTitleTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let onEmptyBackspace: () -> Void

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
