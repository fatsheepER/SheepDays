//
//  QuickAddSheetView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import SwiftUI
import SwiftData

struct QuickAddSheetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.haptics) private var haptics

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

    @State private var iconSystemName = "figure.roll.runningpace"
    @State private var title = ""
    @State private var date = Calendar.current.startOfDay(for: .now)
    @State private var selectedNotebook: Notebook?
    @State private var selectedTagIDs: Set<UUID> = []
    @State private var showOnHome = true
    @State private var pinToTop = false

    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var hasPreparedDefaults = false

    @State private var isDatePickerPresented = false
    @State private var isNotebookCreatorPresented = false
    @State private var newNotebookName = ""
    @State private var newNotebookIconSystemName = ""
    @State private var newNotebookColorHex = ""
    @State private var isCancelling = false
    @FocusState private var isTitleFieldFocused: Bool

    var shouldAutoFocusTitle = false
    var onCreate: (Event) -> Void = { _ in }
    var onCancel: () -> Void = {}
    var onRequestSymbolPicker: (SymbolPickerPresentation) -> Void = { _ in }
    var onRequestTagList: (TagListPresentation) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 10) {
            header

            VStack(spacing: 3) {
                basicInfo
                    .frame(height: 70)

                advancedInfo
                    .frame(height: 40)
            }
            .padding(10)
            .background(
                SDRoundedBackground(
                    topLeading: 35,
                    topTrailing: 35,
                    bottomLeading: 10,
                    bottomTrailing: 10,
                    cornerStyle: .continuous,
                    color: Color(.systemBackground)
                )
            )

            if !isTitleFieldFocused {
                Spacer()
            }

            controls

            if isTitleFieldFocused {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            prepareFormIfNeeded()
        }
        .task(id: shouldAutoFocusTitle) {
            await focusTitleFieldIfNeeded()
        }
        .onChange(of: notebooks.count) {
            syncSelectedNotebookIfNeeded()
        }
        .sheet(isPresented: $isDatePickerPresented) {
            NavigationStack {
                VStack(spacing: 20) {
                    DatePicker(
                        "事件日期",
                        selection: $date,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                }
                .padding()
                .navigationTitle("选择日期")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("完成") {
                            isDatePickerPresented = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $isNotebookCreatorPresented) {
            notebookCreatorSheet
        }
        .alert(
            "保存失败",
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

// MARK: - Subviews
private extension QuickAddSheetView {
    var header: some View {
        HStack(spacing: 10) {
            SDSheetTitleView(iconSystemName: "plus", title: "创建新事件")

            Spacer()
            
            Text(offsetText)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color(.secondaryLabel))
                .contentTransition(.numericText())

        }
    }
    
    var basicInfo: some View {
        HStack(alignment: .center, spacing: 15) {
            Button {
                presentSymbolPicker()
            } label: {
                Image(systemName: displayedIconSystemName)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(selectedNotebookTintColor)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)

            TextField("请输入事件名称", text: $title)
                .font(.system(size: 18, weight: .medium))
                .frame(maxWidth: .infinity)
                .focused($isTitleFieldFocused)

            Button {
                isDatePickerPresented = true
            } label: {
                SDDateBadge(date: date)
            }
            .buttonStyle(.plain)
        }
    }
    
    var advancedInfo: some View {
        HStack {
            Menu {
                if notebooks.isEmpty {
                    Text("暂无事件本")
                } else {
                    Section("选择事件本") {
                        ForEach(notebooks) { notebook in
                            Button {
                                selectedNotebook = notebook
                            } label: {
                                notebookMenuLabel(
                                    for: notebook,
                                    isSelected: notebook.id == selectedNotebook?.id
                                )
                            }
                        }
                    }
                }

                Section {
                    Button {
                        isNotebookCreatorPresented = true
                    } label: {
                        Label("新建事件本…", systemImage: "plus")
                    }
                }
            } label: {
                SDNotebookBadge(notebook: selectedNotebook)
                    .frame(height: 40)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: presentTagList) {
                tagSelectionIcon
            }
            .buttonStyle(.plain)
            .padding(.leading, 10)

            Image(systemName: showOnHome ? "star.fill" : "star")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .onTapGesture {
                    showOnHome.toggle()
                }
                .foregroundStyle(.yellow)
                .padding(.leading, 10)

            Image(systemName: pinToTop ? "pin.fill" : "pin")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .onTapGesture {
                    pinToTop.toggle()
                }
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.leading, 10)
        }
    }
    
    var controls: some View {
        HStack {
            Button(action: cancel) {
                SDSheetActionButton(
                    iconSystemName: "arrow.left",
                    title: "返回",
                    placement: .left,
                    style: .plain
                )
            }
            .buttonStyle(.plain)
            .disabled(isCancelling)

            Button(action: submit) {
                SDSheetActionButton(
                    iconSystemName: "checkmark",
                    title: "保存",
                    placement: .right,
                    style: .prominent
                )
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.6)
        }
    }

    var tagSelectionIcon: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: selectedTagIDs.isEmpty ? "tag" : "tag.fill")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(selectedTagIDs.isEmpty ? Color(.secondaryLabel) : Color.accentColor)
                .frame(width: 18, height: 18)

            if !selectedTagIDs.isEmpty {
                Text("\(selectedTagIDs.count)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                    .offset(x: 9, y: 10)
            }
        }
    }
}

// MARK: - View State
extension QuickAddSheetView {
    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var sanitizedIconSystemName: String? {
        let trimmedIcon = iconSystemName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedIcon.isEmpty ? nil : trimmedIcon
    }

    var displayedIconSystemName: String {
        sanitizedIconSystemName ?? "questionmark.circle"
    }

    var canSubmit: Bool {
        !trimmedTitle.isEmpty && !isSaving
    }

    var offsetText: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let target = calendar.startOfDay(for: date)
        let dayOffset = calendar.dateComponents([.day], from: today, to: target).day ?? 0

        switch dayOffset {
        case 0:
            return "Today"
        case 1:
            return "Tomorrow"
        case -1:
            return "Yesterday"
        case let value where value > 1:
            return "\(value) Days"
        default:
            return "\(abs(dayOffset)) Days Ago"
        }
    }

    var canCreateNotebook: Bool {
        !newNotebookName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // 获取 Image 颜色的逻辑
    var selectedNotebookTintColor: Color {
        guard let hex = selectedNotebook?.colorHex,
              let color = Color(hex: hex) else {
            return .accentColor
        }

        return color
    }
}

// MARK: - Actions
extension QuickAddSheetView {
    func prepareFormIfNeeded() {
        guard !hasPreparedDefaults else {
            syncSelectedNotebookIfNeeded()
            return
        }

        selectedNotebook = notebooks.first
        hasPreparedDefaults = true
    }

    func cancel() {
        guard !isCancelling else {
            return
        }

        haptics.play(.openDetailTap)
        isCancelling = true
        isTitleFieldFocused = false

        Task {
            try? await Task.sleep(for: .milliseconds(220))

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                isCancelling = false
                onCancel()
            }
        }
    }

    func submit() {
        guard canSubmit else {
            return
        }

        haptics.play(.success)
        isSaving = true
        errorMessage = nil
        isTitleFieldFocused = false

        Task {
            try? await Task.sleep(for: .milliseconds(220))

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                let event = buildEvent()
                modelContext.insert(event)

                do {
                    try modelContext.save()
                    onCreate(event)
                } catch {
                    modelContext.delete(event)
                    errorMessage = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }

    func resetForm() {
        iconSystemName = ""
        title = ""
        date = Calendar.current.startOfDay(for: .now)
        selectedNotebook = notebooks.first
        selectedTagIDs = []
        showOnHome = true
        pinToTop = false
        errorMessage = nil
        isSaving = false
    }

    func createNotebook() {
        guard canCreateNotebook else {
            return
        }

        let notebook = Notebook(
            name: newNotebookName.trimmingCharacters(in: .whitespacesAndNewlines),
            colorHex: sanitizedNewNotebookColorHex,
            iconSystemName: sanitizedNewNotebookIconSystemName
        )

        modelContext.insert(notebook)

        do {
            try modelContext.save()
            selectedNotebook = notebook
            resetNotebookCreatorForm()
            isNotebookCreatorPresented = false
        } catch {
            modelContext.delete(notebook)
            errorMessage = error.localizedDescription
        }
    }

    func resetNotebookCreatorForm() {
        newNotebookName = ""
        newNotebookIconSystemName = ""
        newNotebookColorHex = ""
    }
}

// MARK: - Helpers
private extension QuickAddSheetView {
    var sanitizedNewNotebookIconSystemName: String? {
        let trimmedIcon = newNotebookIconSystemName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedIcon.isEmpty ? nil : trimmedIcon
    }

    var sanitizedNewNotebookColorHex: String? {
        let trimmedHex = newNotebookColorHex.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedHex.isEmpty ? nil : trimmedHex
    }

    var notebookCreatorSheet: some View {
        NavigationStack {
            Form {
                TextField("名称", text: $newNotebookName)
                TextField("SF Symbol", text: $newNotebookIconSystemName)
                TextField("颜色 Hex", text: $newNotebookColorHex)
                    .textInputAutocapitalization(.characters)
            }
            .navigationTitle("新建事件本")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        resetNotebookCreatorForm()
                        isNotebookCreatorPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        createNotebook()
                    }
                    .disabled(!canCreateNotebook)
                }
            }
        }
        .presentationDetents([.medium])
    }

    func buildEvent() -> Event {
        Event(
            title: trimmedTitle,
            targetDate: date,
            allDay: true,
            iconSystemName: sanitizedIconSystemName,
            showOnHome: showOnHome,
            pinToTop: pinToTop,
            notebook: selectedNotebook,
            tags: selectedTags
        )
    }

    var selectedTags: [Tag] {
        allTags.filter { selectedTagIDs.contains($0.id) }
    }

    func syncSelectedNotebookIfNeeded() {
        guard let selectedNotebook else {
            self.selectedNotebook = notebooks.first
            return
        }

        if notebooks.contains(where: { $0.id == selectedNotebook.id }) {
            return
        }

        self.selectedNotebook = notebooks.first
    }

    func focusTitleFieldIfNeeded() async {
        guard shouldAutoFocusTitle else {
            return
        }

        try? await Task.sleep(for: .milliseconds(150))

        guard !Task.isCancelled else {
            return
        }

        await MainActor.run {
            isTitleFieldFocused = true
        }
    }

    @ViewBuilder
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

    func presentSymbolPicker() {
        onRequestSymbolPicker(
            SymbolPickerPresentation(
                title: "选择事件图标",
                sections: SFSymbolLibrary.generalSections,
                selectedSystemName: sanitizedIconSystemName,
                tintColor: selectedNotebookTintColor,
                onSelect: applySymbolSelection(_:)
            )
        )
    }

    func applySymbolSelection(_ systemName: String?) {
        iconSystemName = systemName ?? ""
    }

    func presentTagList() {
        isTitleFieldFocused = false
        onRequestTagList(
            TagListPresentation(
                mode: .selection(
                    selectedTagIDs: selectedTagIDs,
                    onSelectionChange: applyTagSelection(_:)
                )
            )
        )
    }

    func applyTagSelection(_ selectedTagIDs: Set<UUID>) {
        self.selectedTagIDs = selectedTagIDs
    }
}

#Preview {
    QuickAddSheetView()
        .modelContainer(quickAddPreviewContainer)
        .padding()
}

private let quickAddPreviewContainer: ModelContainer = {
    let container = ModelContainerProvider.makePreviewContainer()
    let context = container.mainContext

    let notebooks = [
        Notebook(name: "家庭", colorHex: "FF8A65", iconSystemName: "house.fill"),
        Notebook(name: "工作", colorHex: "5C6BC0", iconSystemName: "briefcase.fill"),
        Notebook(name: "旅行", colorHex: "26A69A", iconSystemName: "airplane")
    ]

    notebooks.forEach(context.insert)

    [
        Tag(name: "健康"),
        Tag(name: "暑假计划"),
        Tag(name: "课程项目")
    ].forEach(context.insert)

    return container
}()
