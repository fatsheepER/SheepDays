//
//  NotebookEditorView.swift
//  SheepDays
//
//  Created by Codex on 2026/4/9.
//

import SwiftUI
import SwiftData

struct NotebookEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var notebook: Notebook

    @State private var nameDraft: String
    @State private var iconDraft: String
    @State private var colorHexDraft: String
    @State private var isEditingIcon = false
    @State private var isEditingColorHex = false
    @State private var errorMessage: String?

    var onClose: () -> Void = {}
    var onNotebookUpdated: () -> Void = {}

    init(
        notebook: Notebook,
        onClose: @escaping () -> Void = {},
        onNotebookUpdated: @escaping () -> Void = {}
    ) {
        self.notebook = notebook
        self.onClose = onClose
        self.onNotebookUpdated = onNotebookUpdated
        _nameDraft = State(initialValue: notebook.name)
        _iconDraft = State(initialValue: notebook.iconSystemName ?? "")
        _colorHexDraft = State(initialValue: notebook.colorHex ?? "")
    }

    var body: some View {
        VStack(spacing: 10) {
            contentSection
                .padding(.vertical, 10)

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
        .alert("编辑图标", isPresented: $isEditingIcon) {
            TextField("SF Symbol 名称", text: $iconDraft)
            Button("保存", action: saveIconSystemName)
            Button("取消", role: .cancel) {
                iconDraft = notebook.iconSystemName ?? ""
            }
        } message: {
            Text("直接输入 `iconSystemName` 作为临时方案。")
        }
        .alert("编辑颜色", isPresented: $isEditingColorHex) {
            TextField("颜色 Hex", text: $colorHexDraft)
            Button("保存", action: saveColorHex)
            Button("取消", role: .cancel) {
                colorHexDraft = notebook.colorHex ?? ""
            }
        } message: {
            Text("支持输入 `#FF8A65` 或 `FF8A65`。")
        }
    }
}

private extension NotebookEditorView {
    
    var contentSection: some View {
        HStack {
            // symbol
            Button {
                isEditingIcon = true
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
                    notebook.name = newValue
                    persistChanges()
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
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
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
                    style: .plain
                )
            }
            .buttonStyle(.plain)

            Button(action: archiveNotebook) {
                SDSheetActionButton(
                    iconSystemName: "archivebox",
                    title: "归档",
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

    var previewTintColor: Color {
        guard
            let sanitizedColorHex,
            let color = Color(hex: sanitizedColorHex)
        else {
            return notebook.tintColor
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

    func saveIconSystemName() {
        let trimmedIcon = iconDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        notebook.iconSystemName = trimmedIcon.isEmpty ? nil : trimmedIcon
        persistChanges()
    }

    func saveColorHex() {
        let trimmedHex = colorHexDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedHex = trimmedHex.replacingOccurrences(of: "#", with: "").uppercased()

        guard normalizedHex.isEmpty || Color(hex: normalizedHex) != nil else {
            errorMessage = "颜色 Hex 格式无效"
            return
        }

        colorHexDraft = normalizedHex
        notebook.colorHex = normalizedHex.isEmpty ? nil : normalizedHex
        persistChanges()
    }

    func archiveNotebook() {
        notebook.isArchived = true
        persistChanges()
        onClose()
    }

    func persistChanges() {
        notebook.updatedAt = .now

        do {
            try modelContext.save()
            onNotebookUpdated()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NotebookEditorView(
        notebook: Notebook(
            name: "生活",
            colorHex: "FF8A65",
            iconSystemName: "leaf.fill"
        )
    )
    .modelContainer(ModelContainerProvider.makePreviewContainer())
}
