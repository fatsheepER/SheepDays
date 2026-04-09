//
//  EventDetailView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/6.
//

import SwiftUI
import SwiftData

struct EventDetailView: View {
    @Environment(\.modelContext) private var modelContext
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

    @State private var iconDraft = ""
    @State private var tagNameDraft = ""
    @State private var selectedTagForEditing: Tag?
    @State private var isEditingIcon = false
    @State private var isManagingTag = false
    @State private var isCreatingTag = false
    @State private var errorMessage: String?

    var onClose: () -> Void = {}
    var onEventUpdated: () -> Void = {}

    var body: some View {
        VStack(spacing: 10) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    titleSection
                    notebookAndTagsSection
                    noteSection
                    dateSection
                    showOnHomeSection
                    pinToTopSection
                    importanceLevelSection
                }
                .padding(.top, 24)
                .padding(.horizontal, 10)
            }
            
            controls
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color(.systemGroupedBackground))
                .shadow(color: .black.opacity(0.2), radius: 30, y: 2)
        )
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
        .alert("编辑图标", isPresented: $isEditingIcon) {
            TextField("SF Symbol 名称", text: $iconDraft)
            Button("保存", action: saveIconSystemName)
            Button("取消", role: .cancel) {
                iconDraft = event.iconSystemName ?? ""
            }
        } message: {
            Text("直接输入 `iconSystemName` 作为临时方案。")
        }
        .alert("新建标签", isPresented: $isCreatingTag) {
            TextField("标签名称", text: $tagNameDraft)
            Button("添加", action: createTagFromDraft)
            Button("取消", role: .cancel) {
                tagNameDraft = ""
            }
        } message: {
            Text("输入新的标签名称。")
        }
        .alert(
            selectedTagForEditing?.name ?? "管理标签",
            isPresented: $isManagingTag,
            presenting: selectedTagForEditing
        ) { tag in
            TextField("标签名称", text: $tagNameDraft)
            Button("重命名") {
                renameTag(tag, to: tagNameDraft)
            }
            Button("删除", role: .destructive) {
                removeTag(tag)
            }
            Button("取消", role: .cancel) {
                selectedTagForEditing = nil
                tagNameDraft = ""
            }
        } message: { _ in
            Text("你可以重命名这个标签，或者将它从当前事件移除。")
        }
    }
}

private extension EventDetailView {
    // MARK: - Subviews
    var titleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button {
                    iconDraft = event.iconSystemName ?? ""
                    isEditingIcon = true
                } label: {
                    Image(systemName: event.iconSystemName ?? "calendar")
                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                        .foregroundStyle(eventAccentColor)
                }
                .buttonStyle(.plain)
                
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
                            selectedTagForEditing = tag
                            tagNameDraft = tag.name
                            isManagingTag = true
                        } label: {
                            SDTagBadge(tag: tag)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        tagNameDraft = ""
                        isCreatingTag = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(.secondaryLabel))
                            .padding(10)
                            .background(
                                Capsule()
                                    .foregroundStyle(Color(.quaternarySystemFill))
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
                        .fill(Color(.systemBackground))
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
                                : Color(.tertiaryLabel)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var controls: some View {
        HStack(spacing: 10) {
            // back
            Button {
                onClose()
            } label: {
                SDSheetActionButton(iconSystemName: "arrow.left", title: "返回", placement: .left, style: .bright)
            }
            
            // archive
            Button {
                archiveEvent()
            } label: {
                SDSheetActionButton(iconSystemName: "archivebox", title: "归档", placement: .right, style: .prominent)
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

    var trimmedTagNameDraft: String {
        tagNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var importanceLevelText: String {
        "\(event.importanceLevel)/5"
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
    func saveIconSystemName() {
        let trimmedIcon = iconDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        event.iconSystemName = trimmedIcon.isEmpty ? nil : trimmedIcon
        persistChanges()
    }

    func createTagFromDraft() {
        guard !trimmedTagNameDraft.isEmpty else {
            return
        }

        if let existingTag = allTags.first(where: { $0.normalizedName == trimmedTagNameDraft.lowercased() }) {
            addTag(existingTag)
            tagNameDraft = ""
            return
        }

        let tag = Tag(name: trimmedTagNameDraft)
        modelContext.insert(tag)
        event.tags.append(tag)
        tagNameDraft = ""
        persistChanges()
    }

    func renameTag(_ tag: Tag, to newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return
        }

        if let existingTag = allTags.first(where: { $0.id != tag.id && $0.normalizedName == trimmedName.lowercased() }) {
            errorMessage = "已存在同名标签“\(existingTag.name)”"
            return
        }

        tag.name = trimmedName
        tag.normalizedName = trimmedName.lowercased()
        tag.updatedAt = .now
        selectedTagForEditing = nil
        tagNameDraft = ""
        persistChanges()
    }

    func addTag(_ tag: Tag) {
        guard !event.tags.contains(where: { $0.id == tag.id }) else {
            return
        }

        event.tags.append(tag)
        persistChanges()
    }

    func removeTag(_ tag: Tag) {
        event.tags.removeAll(where: { $0.id == tag.id })
        selectedTagForEditing = nil
        tagNameDraft = ""
        persistChanges()
    }

    func moveToNotebook(_ notebook: Notebook?) {
        event.notebook = notebook
        persistChanges()
    }

    func archiveEvent() {
        event.isArchived = true
        event.archivedAt = .now
        persistChanges()
        onClose()
    }

    func setImportanceLevel(_ level: Int) {
        if level == 1, event.importanceLevel == 1 {
            event.importanceLevel = 0
        } else {
            event.importanceLevel = level
        }

        persistChanges()
    }

    func persistChanges() {
        event.updatedAt = .now

        do {
            try modelContext.save()
            onEventUpdated()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    EventDetailView(event: eventDetailPreviewEvent)
        .modelContainer(eventDetailPreviewContainer)
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

    return container
}()

private let eventDetailPreviewEvent: Event = {
    let context = eventDetailPreviewContainer.mainContext
    let descriptor = FetchDescriptor<Event>()
    return (try? context.fetch(descriptor).first) ?? Event(title: "Preview Event", targetDate: .now)
}()
