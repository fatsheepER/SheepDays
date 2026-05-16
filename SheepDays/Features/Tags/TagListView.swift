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
    @State private var isEditing: Bool
    @State private var nameDrafts: [UUID: String] = [:]
    @State private var isCreatingTag = false
    @State private var newTagName = ""
    @State private var errorMessage: String?
    @State private var pendingDeletedTag: Tag?

    init(
        mode: TagListMode = .management,
        startsEditing: Bool = false,
        onClose: @escaping () -> Void = {}
    ) {
        self.mode = mode
        self.onClose = onClose
        _selectedTagIDs = State(initialValue: mode.initialSelectedTagIDs)
        _isEditing = State(initialValue: startsEditing)
    }

    var body: some View {
        VStack(spacing: 10) {
            header
                .padding(.horizontal, 15)
                .padding(.top, 10)

            content

            Spacer()

            controls
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color(hex: "272D34") ?? Color(.secondarySystemBackground))
        )
        .foregroundStyle(.white)
        .onAppear(perform: syncDraftsIfNeeded)
        .alert("新建标签", isPresented: $isCreatingTag) {
            TextField("标签名称", text: $newTagName)
            Button("保存", action: createTag)
            Button("取消", role: .cancel) {
                newTagName = ""
            }
        } message: {
            Text("输入新的标签名称。")
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
        .confirmationDialog(
            pendingDeletedTag?.name ?? "删除标签",
            isPresented: pendingDeleteIsPresented,
            presenting: pendingDeletedTag
        ) { tag in
            Button("删除", role: .destructive) {
                deleteTag(tag)
            }

            Button("取消", role: .cancel) {
                pendingDeletedTag = nil
            }
        } message: { tag in
            Text("删除后，这个标签会从所有事件中移除。")
        }
    }
}

private extension TagListView {
    var isSelectionMode: Bool {
        switch mode {
        case .management:
            return false
        case .selection:
            return true
        }
    }

    var pendingDeleteIsPresented: Binding<Bool> {
        Binding(
            get: { pendingDeletedTag != nil },
            set: { isPresented in
                if !isPresented {
                    pendingDeletedTag = nil
                }
            }
        )
    }

    var header: some View {
        HStack {
            Image(systemName: "tag")

            Text("标签")

            Spacer()

            SDHeaderActionButton(
                iconSystemName: "xmark",
                foregroundColor: .white,
                backgroundColor: Color(.darkGray),
                action: onClose
            )
        }
        .font(.system(size: 20, weight: .semibold))
    }

    var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                Color.clear.frame(height: 10)

                if tags.isEmpty {
                    emptyState
                } else {
                    ForEach(tags) { tag in
                        tagRow(for: tag)
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding(.horizontal, 15)
    }

    var emptyState: some View {
        Text("暂无标签")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color(.lightGray))
            .frame(maxWidth: .infinity, minHeight: 120)
    }

    var controls: some View {
        HStack {
            Button {
                toggleEditing()
            } label: {
                SDSheetActionButton(
                    iconSystemName: isEditing ? "checkmark" : "pencil",
                    title: isEditing ? "完成" : "编辑",
                    placement: .left,
                    style: .lightTransparent
                )
            }
            .buttonStyle(.plain)

            Button {
                newTagName = ""
                isCreatingTag = true
            } label: {
                SDSheetActionButton(
                    iconSystemName: "plus",
                    title: "新建",
                    placement: .right,
                    style: .prominent
                )
            }
            .buttonStyle(.plain)
        }
    }

    func tagRow(for tag: Tag) -> some View {
        HStack(spacing: 10) {
            tagBadge(for: tag)

            Spacer()

            Text("\(activeEventCount(for: tag)) 个事件")
                .foregroundStyle(selectedTagIDs.contains(tag.id) ? Color(.white) : Color(.lightGray))

            if isEditing {
                Button {
                    pendingDeletedTag = tag
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red.opacity(0.75))
                        .padding(10)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.2))
                        )
                }
                .buttonStyle(.plain)
                .transition(.blurReplace)
            }
        }
        .font(.system(size: 15, weight: .semibold))
    }

    @ViewBuilder
    func tagBadge(for tag: Tag) -> some View {
        if isEditing {
            tagBadgeContent(for: tag, isSelected: false)
                .transition(.blurReplace)
        } else if isSelectionMode {
            Button {
                toggleSelection(for: tag)
            } label: {
                tagBadgeContent(for: tag, isSelected: selectedTagIDs.contains(tag.id))
            }
            .buttonStyle(.plain)
            .transition(.blurReplace)
        } else {
            tagBadgeContent(for: tag, isSelected: false)
                .transition(.blurReplace)
        }
    }

    func tagBadgeContent(for tag: Tag, isSelected: Bool) -> some View {
        HStack(spacing: 0) {
            Image(systemName: "number")

            if isEditing {
                TextField("标签名称", text: nameDraftBinding(for: tag))
                    .textFieldStyle(.plain)
                    .frame(minWidth: 40)
            } else {
                Text(tag.name)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(
            Capsule(style: .continuous)
                .fill(Color(.darkGray))
        )
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(Color(.white), lineWidth: isSelected ? 2 : 0)
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

    func toggleEditing() {
        if isEditing {
            finishEditing()
        } else {
            beginEditing()
        }
    }

    func beginEditing() {
        syncDrafts()
        withAnimation {
            isEditing = true
        }
    }

    func finishEditing() {
        guard validateDrafts() else {
            return
        }

        for tag in tags {
            let trimmedName = trimmedDraft(for: tag)

            guard tag.name != trimmedName else {
                continue
            }

            tag.name = trimmedName
            tag.normalizedName = trimmedName.lowercased()
            tag.updatedAt = .now
        }

        do {
            try modelContext.save()
            withAnimation {
                isEditing = false
            }
            syncDrafts()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }

    func validateDrafts() -> Bool {
        let trimmedNames = tags.map { trimmedDraft(for: $0) }

        guard trimmedNames.allSatisfy({ !$0.isEmpty }) else {
            errorMessage = "标签名称不能为空"
            return false
        }

        let normalizedNames = trimmedNames.map { $0.lowercased() }
        guard Set(normalizedNames).count == normalizedNames.count else {
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
        guard nameDrafts.isEmpty || isEditing else {
            return
        }

        syncDrafts()
    }

    func syncDrafts() {
        nameDrafts = Dictionary(uniqueKeysWithValues: tags.map { ($0.id, $0.name) })
    }

    func createTag() {
        let trimmedName = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        newTagName = ""

        guard !trimmedName.isEmpty else {
            return
        }

        guard tags.contains(where: { $0.normalizedName == trimmedName.lowercased() }) == false else {
            errorMessage = "已存在同名标签"
            return
        }

        let tag = Tag(name: trimmedName)
        modelContext.insert(tag)

        do {
            try modelContext.save()
            nameDrafts[tag.id] = tag.name
        } catch {
            modelContext.delete(tag)
            errorMessage = error.localizedDescription
        }
    }

    func deleteTag(_ tag: Tag) {
        pendingDeletedTag = nil
        selectedTagIDs.remove(tag.id)
        notifySelectionChangeIfNeeded()

        modelContext.delete(tag)

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
        guard !isEditing else {
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
