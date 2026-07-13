//
//  NotebookEditorCard.swift
//  SheepDays
//
//  Created by Codex on 2026/7/13.
//

import SwiftUI

struct NotebookEditDraft: Equatable {
    var sourceNotebookID: UUID?
    var name: String
    var iconSystemName: String?
    var colorHex: String?

    static let empty = NotebookEditDraft(
        sourceNotebookID: nil,
        name: "",
        iconSystemName: nil,
        colorHex: nil
    )

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var displayedIconSystemName: String {
        iconSystemName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? "book.closed"
    }

    var tintColor: Color {
        guard let colorHex,
              let color = Color(hex: colorHex) else {
            return .accentColor
        }

        return color
    }
}

struct NotebookEditorCard: View {
    @Binding var draft: NotebookEditDraft
    let nameFocus: FocusState<Bool>.Binding
    let onRequestSymbolPicker: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            editorHeader

            NotebookDailyGraph(
                eventDays: [],
                today: Calendar.current.startOfDay(for: .now),
                accentColor: draft.tintColor,
                height: 45
            )
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private var editorHeader: some View {
        HStack(alignment: .center, spacing: 5) {
            Button(action: onRequestSymbolPicker) {
                Image(systemName: draft.displayedIconSystemName)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("选择事件本图标")

            TextField("事件本名称", text: $draft.name)
                .font(.system(size: 22, weight: .semibold))
                .textFieldStyle(.plain)
                .focused(nameFocus)
                .submitLabel(.done)
                .lineLimit(1)
        }
        .foregroundStyle(draft.tintColor)
        .padding(.horizontal, 5)
        .padding(.vertical, 10)
        .frame(minHeight: 55)
        .background(
            SDRoundedBackground(
                topLeading: 20,
                topTrailing: 20,
                bottomLeading: 20,
                bottomTrailing: 10,
                cornerStyle: .continuous,
                color: draft.tintColor.opacity(0.2)
            )
        )
    }
}

struct NotebookCreationSurface: View {
    @Binding var draft: NotebookEditDraft
    let nameFocus: FocusState<Bool>.Binding
    let showsControls: Bool
    let onBack: () -> Void
    let onSave: () -> Void
    let onRequestSymbolPicker: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            NotebookEditorControls(
                canSave: !draft.trimmedName.isEmpty,
                onBack: onBack,
                onSave: onSave
            )
            .opacity(showsControls ? 1 : 0)

            NotebookEditorCard(
                draft: $draft,
                nameFocus: nameFocus,
                onRequestSymbolPicker: onRequestSymbolPicker
            )
        }
    }
}

struct NotebookEditorControls: View {
    let canSave: Bool
    let onBack: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack {
            Spacer()
            
            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 0) {
                    editorButton(
                        systemName: "chevron.left",
                        fontSize: 22,
                        accessibilityLabel: "返回",
                        action: onBack
                    )

                    editorButton(
                        systemName: "checkmark",
                        fontSize: 22,
                        accessibilityLabel: "保存",
                        action: onSave
                    )
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.35)
                }
                .glassEffect(.regular.interactive())
            }
        }
    }

    private func editorButton(
        systemName: String,
        fontSize: CGFloat,
        accessibilityLabel: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: fontSize))
                .foregroundStyle(Color(.label))
                .frame(width: 40, height: 40)
                .padding(5)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

private struct NotebookEditorCardPreview: View {
    @State private var draft = NotebookEditDraft(
        sourceNotebookID: nil,
        name: "生活",
        iconSystemName: "leaf.fill",
        colorHex: "FF8A65"
    )
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            NotebookEditorControls(
                canSave: !draft.trimmedName.isEmpty,
                onBack: {},
                onSave: {}
            )

            NotebookEditorCard(
                draft: $draft,
                nameFocus: $isNameFocused,
                onRequestSymbolPicker: {}
            )
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    NotebookEditorCardPreview()
}
