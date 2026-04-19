//
//  NotebookEditorView.swift
//  SheepDays
//
//  Created by Codex on 2026/4/9.
//

import SwiftUI
import SwiftData

enum NotebookEditorOption {
    case create
    case edit(Notebook)
}

struct NotebookEditorView: View {
    @Environment(\.modelContext) private var modelContext

    let option: NotebookEditorOption

    @State private var nameDraft: String
    @State private var iconDraft: String
    @State private var colorHexDraft: String
    @State private var isEditingColorHex = false
    @State private var errorMessage: String?

    var onClose: () -> Void = {}
    var onNotebookUpdated: () -> Void = {}
    var onRequestSymbolPicker: (SymbolPickerPresentation) -> Void = { _ in }

    init(
        option: NotebookEditorOption,
        onClose: @escaping () -> Void = {},
        onNotebookUpdated: @escaping () -> Void = {},
        onRequestSymbolPicker: @escaping (SymbolPickerPresentation) -> Void = { _ in }
    ) {
        self.option = option
        self.onClose = onClose
        self.onNotebookUpdated = onNotebookUpdated
        self.onRequestSymbolPicker = onRequestSymbolPicker

        switch option {
        case .create:
            _nameDraft = State(initialValue: "")
            _iconDraft = State(initialValue: "")
            _colorHexDraft = State(initialValue: "")
        case let .edit(notebook):
            _nameDraft = State(initialValue: notebook.name)
            _iconDraft = State(initialValue: notebook.iconSystemName ?? "")
            _colorHexDraft = State(initialValue: notebook.colorHex ?? "")
        }
    }

    var body: some View {
        VStack(spacing: 15) {
            header
                .padding(.top, 5)
                .padding(.horizontal, 5)

            contentSection

            controls
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color(.systemBackground))
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
        .alert("编辑颜色", isPresented: $isEditingColorHex) {
            TextField("颜色 Hex", text: $colorHexDraft)
            Button("保存", action: saveColorHex)
            Button("取消", role: .cancel) {
                colorHexDraft = currentPersistedColorHex
            }
        } message: {
            Text("支持输入 `#FF8A65` 或 `FF8A65`。")
        }
    }
}

// MARK: - Subviews
private extension NotebookEditorView {
    
    var header: some View {
        HStack {
            SDSheetTitleView(iconSystemName: "plus.app", title: "创建新事件本")
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    var contentSection: some View {
        HStack {
            // symbol
            Button {
                presentSymbolPicker()
            } label: {
                Image(systemName: previewIconSystemName)
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .foregroundStyle(.white.opacity(0.3))
                    )
            }
            
            // name
            TextField("请输入事件本名称", text: $nameDraft)
                .onChange(of: nameDraft) { _, newValue in
                    guard case let .edit(notebook) = option else {
                        return
                    }

                    notebook.name = newValue
                    persistChanges(for: notebook)
                }
                .textFieldStyle(.plain)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .foregroundStyle(.white.opacity(0.3))
                )
            
            // palette
            Button {
                isEditingColorHex = true
            } label: {
                Image(systemName: "swatchpalette")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: 70)
        .background(
            SDRoundedBackground(topLeading: 25, topTrailing: 25, bottomLeading: 25, bottomTrailing: 10, cornerStyle: .continuous, color: previewTintColor)
        )
    }

    var controls: some View {
        HStack(spacing: 10) {
            Button(action: onClose) {
                SDSheetActionButton(
                    iconSystemName: "arrow.left",
                    title: "返回",
                    placement: .left,
                    style: .secondary
                )
            }
            .buttonStyle(.plain)

            Button(action: primaryAction) {
                SDSheetActionButton(
                    iconSystemName: primaryActionIconSystemName,
                    title: primaryActionTitle,
                    placement: .right,
                    style: .prominent
                )
            }
            .buttonStyle(.plain)
        }
    }

    var draftBadge: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Image(systemName: previewIconSystemName)
            Text(previewTitle)
        }
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(.white)
        .padding(10)
        .background(
            SDRoundedBackground(
                topLeading: 15,
                topTrailing: 15,
                bottomLeading: 15,
                bottomTrailing: 5,
                cornerStyle: .continuous,
                color: previewTintColor
            )
        )
        .frame(height: 35)
    }

    var previewTitle: String {
        let trimmedName = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "未命名事件本" : trimmedName
    }

    var previewIconSystemName: String {
        let trimmedIcon = iconDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedIcon.isEmpty ? "book.closed" : trimmedIcon
    }

    var sanitizedIconDraft: String? {
        iconDraft.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    var previewTintColor: Color {
        guard
            let sanitizedColorHex,
            let color = Color(hex: sanitizedColorHex)
        else {
            return existingNotebook?.tintColor ?? .accentColor
        }

        return color
    }

    var displayColorHex: String {
        if let sanitizedColorHex {
            return "#\(sanitizedColorHex)"
        }

        return "未设置颜色"
    }

    var sanitizedColorHex: String? {
        let trimmedHex = colorHexDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedHex = trimmedHex.replacingOccurrences(of: "#", with: "").uppercased()
        return normalizedHex.isEmpty ? nil : normalizedHex
    }

    var existingNotebook: Notebook? {
        if case let .edit(notebook) = option {
            return notebook
        }

        return nil
    }

    var currentPersistedIconSystemName: String {
        existingNotebook?.iconSystemName ?? ""
    }

    var currentPersistedColorHex: String {
        existingNotebook?.colorHex ?? ""
    }

    var primaryActionTitle: String {
        switch option {
        case .create:
            return "创建"
        case .edit:
            return "归档"
        }
    }

    var primaryActionIconSystemName: String {
        switch option {
        case .create:
            return "plus"
        case .edit:
            return "archivebox"
        }
    }

    @ViewBuilder
    func sectionTitle(_ title: String, _ imageName: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Image(systemName: imageName)
                .font(.system(size: 18, weight: .medium))

            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(.secondaryLabel))
        }
        .frame(height: 35)
        .foregroundStyle(Color(.secondaryLabel))
    }

    func saveColorHex() {
        let trimmedHex = colorHexDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedHex = trimmedHex.replacingOccurrences(of: "#", with: "").uppercased()

        guard normalizedHex.isEmpty || Color(hex: normalizedHex) != nil else {
            errorMessage = "颜色 Hex 格式无效"
            return
        }

        colorHexDraft = normalizedHex

        guard case let .edit(notebook) = option else {
            return
        }

        notebook.colorHex = normalizedHex.isEmpty ? nil : normalizedHex
        persistChanges(for: notebook)
    }

    func primaryAction() {
        switch option {
        case .create:
            createNotebook()
        case .edit:
            archiveNotebook()
        }
    }

    func createNotebook() {
        let trimmedName = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "事件本名称不能为空"
            return
        }

        guard let sanitizedColorHex = sanitizedColorHex else {
            let notebook = Notebook(
                name: trimmedName,
                colorHex: nil,
                iconSystemName: iconDraft.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            )
            modelContext.insert(notebook)
            persistChanges(for: notebook, shouldClose: true)
            return
        }

        guard Color(hex: sanitizedColorHex) != nil else {
            errorMessage = "颜色 Hex 格式无效"
            return
        }

        let notebook = Notebook(
            name: trimmedName,
            colorHex: sanitizedColorHex,
            iconSystemName: iconDraft.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        )
        modelContext.insert(notebook)
        persistChanges(for: notebook, shouldClose: true)
    }

    func archiveNotebook() {
        guard case let .edit(notebook) = option else {
            return
        }

        notebook.isArchived = true
        persistChanges(for: notebook, shouldClose: true)
    }

    func persistChanges(for notebook: Notebook, shouldClose: Bool = false) {
        notebook.updatedAt = .now

        do {
            try modelContext.save()
            onNotebookUpdated()
            if shouldClose {
                onClose()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func presentSymbolPicker() {
        onRequestSymbolPicker(
            SymbolPickerPresentation(
                title: "选择事件本图标",
                sections: SFSymbolLibrary.notebookSections,
                selectedSystemName: sanitizedIconDraft,
                tintColor: previewTintColor,
                onSelect: applySymbolSelection(_:)
            )
        )
    }

    func applySymbolSelection(_ systemName: String?) {
        iconDraft = systemName ?? ""

        guard case let .edit(notebook) = option else {
            return
        }

        notebook.iconSystemName = systemName
        persistChanges(for: notebook)
    }
}

#Preview {
    NotebookEditorView(
        option: .edit(
            Notebook(
                name: "生活",
                colorHex: "FF8A65",
                iconSystemName: "leaf.fill"
            )
        )
    )
    .modelContainer(ModelContainerProvider.makePreviewContainer())
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
