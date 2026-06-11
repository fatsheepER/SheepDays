//
//  TagListView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/5/14.
//

import SwiftUI
import SwiftData

struct TagListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(
        sort: [
            SortDescriptor(\Tag.name),
            SortDescriptor(\Tag.createdAt)
        ]
    )
    private var tags: [Tag]

    let mode: TagListMode
    let onClose: () -> Void

    @State private var selectedTagIDs: Set<UUID>
    @State private var editingTagID: UUID?
    @State private var shouldStartEditingFirstTag: Bool
    @State private var nameDrafts: [UUID: String] = [:]
    @State private var newTagName = ""
    @State private var errorMessage: String?
    @State private var pendingDeletedTagID: UUID?
    @FocusState private var focusedTagID: UUID?
    @FocusState private var isNewTagNameFocused: Bool

    init(
        mode: TagListMode = .management,
        startsEditing: Bool = false,
        onClose: @escaping () -> Void = {}
    ) {
        self.mode = mode
        self.onClose = onClose
        _selectedTagIDs = State(initialValue: mode.initialSelectedTagIDs)
        _shouldStartEditingFirstTag = State(initialValue: startsEditing)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    if tags.isEmpty {
                        TagListEmptyRow()
                            .listRowStyle()
                    } else {
                        ForEach(tags) { tag in
                            tagRow(for: tag)
                                .transition(tagRowTransition)
                                .listRowStyle()
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        beginEditing(tag)
                                    } label: {
                                        Image(systemName: "pencil")
                                    }
                                    .tint(Color(.secondarySystemFill))

                                    Button(role: .destructive) {
                                        pendingDeletedTagID = tag.id
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                        }
                    }
                }
                .animation(tagRowAnimation, value: tagIDs)

                VStack {
                    Spacer()

                    newTagRow
                        .listRowStyle()
                }
                .padding()

            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(tagListBackgroundColor.ignoresSafeArea())
            .foregroundStyle(.white)
            .navigationTitle("标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: close) {
                        Image(systemName: "xmark")
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
        .background(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(tagListBackgroundColor)
        )
        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .stroke(Color(.separator), lineWidth: 2)
        }
        .onAppear {
            syncDraftsIfNeeded()
            focusFirstTagIfNeeded()
        }
        .onChange(of: tagIDs) { _, _ in
            syncDraftsIfNeeded()
            resetEditingTagIfNeeded()
            resetDeleteConfirmationIfNeeded()
            focusFirstTagIfNeeded()
        }
        .onChange(of: focusedTagID) { oldValue, newValue in
            guard oldValue != newValue,
                  let oldValue,
                  let tag = tags.first(where: { $0.id == oldValue })
            else {
                return
            }

            _ = finishEditing(tag)
        }
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
    }
}

private extension TagListView {
    var tagIDs: [UUID] {
        tags.map(\.id)
    }

    var isSelectionMode: Bool {
        switch mode {
        case .management:
            return false
        case .selection:
            return true
        }
    }

    var newTagRow: some View {
        TagListNewTagRow(
            name: $newTagName,
            isFocused: $isNewTagNameFocused,
            onSubmit: createTag
        )
    }

    func tagRow(for tag: Tag) -> some View {
        TagListTagRow(
            tag: tag,
            eventCount: activeEventCount(for: tag),
            isSelected: selectedTagIDs.contains(tag.id),
            isSelectionMode: isSelectionMode,
            isEditing: editingTagID == tag.id,
            nameDraft: nameDraftBinding(for: tag),
            focusedTagID: $focusedTagID,
            onToggleSelection: {
                toggleSelection(for: tag)
            },
            onSubmit: {
                _ = finishEditing(tag)
            }
        )
        .confirmationDialog(
            "删除标签",
            isPresented: deleteDialogIsPresented(for: tag)
        ) {
            Button("删除", role: .destructive) {
                deleteTag(tag)
            }

            Button("取消", role: .cancel) {
                pendingDeletedTagID = nil
            }
        } message: {
            Text("删除后，这个标签会从所有事件中移除。")
        }
    }

    func nameDraftBinding(for tag: Tag) -> Binding<String> {
        Binding(
            get: { nameDrafts[tag.id] ?? tag.name },
            set: { nameDrafts[tag.id] = $0 }
        )
    }

    func activeEventCount(for tag: Tag) -> Int {
        tag.events.filter { !$0.isArchived }.count
    }

    func close() {
        guard commitEditingTagIfNeeded() else {
            return
        }

        onClose()
    }

    func deleteDialogIsPresented(for tag: Tag) -> Binding<Bool> {
        Binding(
            get: { pendingDeletedTagID == tag.id },
            set: { isPresented in
                if !isPresented, pendingDeletedTagID == tag.id {
                    pendingDeletedTagID = nil
                }
            }
        )
    }

    func beginEditing(_ tag: Tag) {
        pendingDeletedTagID = nil

        guard editingTagID != tag.id else {
            focusEditingTag(tag)
            return
        }

        guard commitEditingTagIfNeeded() else {
            return
        }

        nameDrafts[tag.id] = tag.name

        withAnimation(.snappy(duration: 0.2, extraBounce: 0)) {
            editingTagID = tag.id
        }

        focusEditingTag(tag)
    }

    @discardableResult
    func finishEditing(_ tag: Tag) -> Bool {
        let trimmedName = trimmedDraft(for: tag)

        guard validateDraft(trimmedName, for: tag) else {
            focusEditingTag(tag)
            return false
        }

        guard tag.name != trimmedName else {
            endEditing(for: tag)
            syncDraft(for: tag)
            return true
        }

        tag.name = trimmedName
        tag.normalizedName = trimmedName.lowercased()
        tag.updatedAt = .now

        do {
            try modelContext.save()
            endEditing(for: tag)
            syncDraft(for: tag)
            return true
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
            focusEditingTag(tag)
            return false
        }
    }

    func commitEditingTagIfNeeded() -> Bool {
        guard let editingTagID else {
            return true
        }

        guard let tag = tags.first(where: { $0.id == editingTagID }) else {
            self.editingTagID = nil
            focusedTagID = nil
            return true
        }

        return finishEditing(tag)
    }

    func endEditing(for tag: Tag) {
        guard editingTagID == tag.id else {
            return
        }

        withAnimation(.snappy(duration: 0.2, extraBounce: 0)) {
            editingTagID = nil
        }

        focusedTagID = nil
    }

    func focusEditingTag(_ tag: Tag) {
        Task { @MainActor in
            focusedTagID = tag.id
        }
    }

    func focusFirstTagIfNeeded() {
        guard shouldStartEditingFirstTag,
              editingTagID == nil,
              let firstTag = tags.first
        else {
            return
        }

        shouldStartEditingFirstTag = false
        beginEditing(firstTag)
    }

    func resetEditingTagIfNeeded() {
        guard let editingTagID,
              tags.contains(where: { $0.id == editingTagID }) == false
        else {
            return
        }

        self.editingTagID = nil
        focusedTagID = nil
    }

    func resetDeleteConfirmationIfNeeded() {
        guard let pendingDeletedTagID,
              tags.contains(where: { $0.id == pendingDeletedTagID }) == false
        else {
            return
        }

        self.pendingDeletedTagID = nil
    }

    func validateDraft(_ trimmedName: String, for tag: Tag) -> Bool {
        guard !trimmedName.isEmpty else {
            errorMessage = "标签名称不能为空"
            return false
        }

        let normalizedName = trimmedName.lowercased()
        guard tags.contains(where: { $0.id != tag.id && $0.normalizedName == normalizedName }) == false else {
            errorMessage = "已存在同名标签"
            return false
        }

        return true
    }

    func trimmedDraft(for tag: Tag) -> String {
        (nameDrafts[tag.id] ?? tag.name)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func syncDraftsIfNeeded() {
        guard nameDrafts.isEmpty || editingTagID == nil else {
            return
        }

        syncDrafts()
    }

    func syncDrafts() {
        nameDrafts = Dictionary(uniqueKeysWithValues: tags.map { ($0.id, $0.name) })
    }

    func syncDraft(for tag: Tag) {
        nameDrafts[tag.id] = tag.name
    }

    func createTag() {
        let trimmedName = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            return
        }

        guard tags.contains(where: { $0.normalizedName == trimmedName.lowercased() }) == false else {
            errorMessage = "已存在同名标签"
            return
        }

        let tag = Tag(name: trimmedName)
        withAnimation(tagRowAnimation) {
            modelContext.insert(tag)
        }

        do {
            try modelContext.save()
            newTagName = ""
            nameDrafts[tag.id] = tag.name
            isNewTagNameFocused = true
        } catch {
            withAnimation(tagRowAnimation) {
                modelContext.delete(tag)
            }
            errorMessage = error.localizedDescription
        }
    }

    func deleteTag(_ tag: Tag) {
        withAnimation(tagRowAnimation) {
            selectedTagIDs.remove(tag.id)

            if pendingDeletedTagID == tag.id {
                pendingDeletedTagID = nil
            }

            if editingTagID == tag.id {
                editingTagID = nil
                focusedTagID = nil
            }

            modelContext.delete(tag)
        }

        notifySelectionChangeIfNeeded()

        do {
            try modelContext.save()
            nameDrafts.removeValue(forKey: tag.id)
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
            selectedTagIDs = mode.initialSelectedTagIDs
        }
    }

    func toggleSelection(for tag: Tag) {
        guard isSelectionMode, editingTagID == nil else {
            return
        }

        if selectedTagIDs.contains(tag.id) {
            selectedTagIDs.remove(tag.id)
        } else {
            selectedTagIDs.insert(tag.id)
        }

        notifySelectionChangeIfNeeded()
    }

    func notifySelectionChangeIfNeeded() {
        switch mode {
        case .management:
            return
        case .selection(_, let onSelectionChange):
            onSelectionChange(selectedTagIDs)
        }
    }
}

private let tagListBackgroundColor = Color(hex: "272D34")!
private let tagRowAnimation = Animation.snappy(duration: 0.28, extraBounce: 0)
private let tagRowTransition = AnyTransition.asymmetric(
    insertion: .scale(scale: 0.94).combined(with: .opacity),
    removal: .scale(scale: 0.94).combined(with: .opacity)
)

private extension View {
    func listRowStyle() -> some View {
        listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

private struct TagListEmptyRow: View {
    var body: some View {
        Text("暂无标签")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color(.lightGray))
            .frame(maxWidth: .infinity, minHeight: 120)
    }
}

private struct TagListTagRow: View {
    let tag: Tag
    let eventCount: Int
    let isSelected: Bool
    let isSelectionMode: Bool
    let isEditing: Bool
    @Binding var nameDraft: String
    let focusedTagID: FocusState<UUID?>.Binding
    let onToggleSelection: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            tagBadge

            Spacer(minLength: 8)

            Text("\(eventCount) 个事件")
                .foregroundStyle(isSelected ? Color(.white) : Color(.lightGray))
        }
        .font(.system(size: 15, weight: .semibold))
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggleSelection)
        .animation(.snappy(duration: 0.2, extraBounce: 0), value: isEditing)
        .animation(.snappy(duration: 0.2, extraBounce: 0), value: isSelected)
    }

    private var tagBadge: some View {
        HStack(spacing: 0) {
            Image(systemName: "number")

            if isEditing {
                TextField("标签名称", text: $nameDraft)
                    .textFieldStyle(.plain)
                    .focused(focusedTagID, equals: tag.id)
                    .submitLabel(.done)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .frame(minWidth: 40)
                    .onSubmit(onSubmit)
                    .transition(.blurReplace)
            } else {
                Text(tag.name)
                    .transition(.blurReplace)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(
            Capsule(style: .continuous)
                .fill(Color(.secondarySystemFill))
        )
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(Color(.white), lineWidth: isSelected && isSelectionMode ? 2 : 0)
        }
    }
}

private struct TagListNewTagRow: View {
    @Binding var name: String
    let isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus")
                .foregroundStyle(.primary)
                .frame(width: 24, height: 24)

            TextField("新建标签", text: $name)
                .textFieldStyle(.plain)
                .focused(isFocused)
                .submitLabel(.done)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit(onSubmit)

            Button(action: onSubmit) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(canSubmit ? .white : Color(.lightGray))
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
            .accessibilityLabel("创建标签")
        }
        .font(.system(size: 15, weight: .semibold))
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(
            Capsule(style: .continuous)
                .foregroundStyle(Color(.secondarySystemFill))
                .glassEffect()
        )
    }
}

#Preview("Management") {
    TagListView()
        .padding(.horizontal, 40)
        .frame(height: 600)
        .background(Color(.secondarySystemBackground))
        .modelContainer(tagListPreviewContainer)
}

#Preview("Selection") {
    TagListView(
        mode: .selection(
            selectedTagIDs: tagListPreviewSelectedIDs,
            onSelectionChange: { _ in }
        )
    )
    .padding(.horizontal, 40)
    .frame(height: 600)
    .background(Color(.secondarySystemBackground))
    .modelContainer(tagListPreviewContainer)
}

#Preview("Editing") {
    TagListView(startsEditing: true)
        .padding(.horizontal, 40)
        .frame(height: 600)
        .background(Color(.secondarySystemBackground))
        .modelContainer(tagListPreviewContainer)
}

private let tagListPreviewContainer: ModelContainer = {
    let container = ModelContainerProvider.makePreviewContainer()
    let context = container.mainContext

    let tags = [
        Tag(name: "暑假计划"),
        Tag(name: "新技能"),
        Tag(name: "健康")
    ]

    let event = Event(
        title: "预览事件",
        targetDate: .now,
        allDay: true,
        tags: Array(tags.prefix(2))
    )

    tags.forEach(context.insert)
    context.insert(event)

    return container
}()

private let tagListPreviewSelectedIDs: Set<UUID> = {
    var descriptor = FetchDescriptor<Tag>(
        sortBy: [
            SortDescriptor(\Tag.name),
            SortDescriptor(\Tag.createdAt)
        ]
    )
    descriptor.fetchLimit = 1

    guard let tag = try? tagListPreviewContainer.mainContext.fetch(descriptor).first else {
        return []
    }

    return [tag.id]
}()
