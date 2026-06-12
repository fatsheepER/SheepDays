//
//  EventDetailNotebookTagsSection.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/6/12.
//

import SwiftUI

struct EventDetailNotebookTagsSection: View {
    let notebooks: [Notebook]
    let selectedNotebook: Notebook?
    let tags: [Tag]
    let onMoveToNotebook: (Notebook) -> Void
    let onRequestTagList: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Menu {
                    if notebooks.isEmpty {
                        Text("暂无事件本")
                    } else {
                        Section("选择事件本") {
                            ForEach(notebooks) { notebook in
                                Button {
                                    onMoveToNotebook(notebook)
                                } label: {
                                    notebookMenuLabel(
                                        for: notebook,
                                        isSelected: notebook.id == selectedNotebook?.id
                                    )
                                }
                            }
                        }
                    }
                } label: {
                    SDNotebookBadge(notebook: selectedNotebook)
                        .frame(height: 40)
                }
                .buttonStyle(.plain)

                ForEach(sortedTags) { tag in
                    Button {
                        onRequestTagList()
                    } label: {
                        SDTagBadge(tag: tag)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    onRequestTagList()
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

private extension EventDetailNotebookTagsSection {
    var sortedTags: [Tag] {
        tags.sorted(by: { $0.name.localizedCompare($1.name) == .orderedAscending })
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
}

#Preview {
    let notebooks = [
        Notebook(name: "家庭", colorHex: "FF8A65", iconSystemName: "house.fill"),
        Notebook(name: "工作", colorHex: "5C6BC0", iconSystemName: "briefcase.fill"),
        Notebook(name: "旅行", colorHex: "26A69A", iconSystemName: "airplane")
    ]
    let tags = [
        Tag(name: "健康"),
        Tag(name: "暑假计划")
    ]

    EventDetailNotebookTagsSection(
        notebooks: notebooks,
        selectedNotebook: notebooks[1],
        tags: tags,
        onMoveToNotebook: { _ in },
        onRequestTagList: {}
    )
    .padding()
}
