//
//  NotebookListView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import SwiftUI
import SwiftData

struct NotebooksSheetView: View {
    @State private var isEditing = false

    @Query(
        filter: #Predicate<Notebook> { !$0.isArchived },
        sort: [
            SortDescriptor(\Notebook.updatedAt, order: .reverse),
            SortDescriptor(\Notebook.createdAt, order: .reverse)
        ]
    )
    private var notebooks: [Notebook]

    let onBack: () -> Void
    var onCreateNotebook: () -> Void = {}
    var onEditNotebook: (Notebook) -> Void = { _ in }
    var onOpenNotebook: (Notebook) -> Void = { _ in }

    private let previewEventLimit = 3

    var body: some View {
        VStack(spacing: 15) {
            header

            if notebookSummaries.isEmpty {
                emptyState
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 15) {
                        ForEach(notebookSummaries) { summary in
                            NotebookSummaryCard(
                                summary: summary,
                                isEditing: isEditing,
                                onAccessoryTap: {
                                    handleAccessoryTap(for: summary.notebook)
                                },
                                onTap: {
                                    guard !isEditing else {
                                        return
                                    }

                                    onOpenNotebook(summary.notebook)
                                }
                            )
                        }
                    }
                }
            }

            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - View State
private extension NotebooksSheetView {
    var notebookSummaries: [NotebookSummary] {
        notebooks.map(makeSummary(for:))
    }

    func makeSummary(for notebook: Notebook) -> NotebookSummary {
        let activeEvents = notebook.events
            .filter { !$0.isArchived }
            .sorted { lhs, rhs in
                notebookEventSort(lhs: lhs, rhs: rhs)
            }
        let previewEvents = Array(activeEvents.prefix(previewEventLimit))

        return NotebookSummary(
            notebook: notebook,
            activeEventCount: activeEvents.count,
            previewEvents: previewEvents,
            remainingEventCount: max(0, activeEvents.count - previewEvents.count)
        )
    }

    func notebookEventSort(lhs: Event, rhs: Event) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let lhsDay = calendar.startOfDay(for: lhs.targetDate)
        let rhsDay = calendar.startOfDay(for: rhs.targetDate)

        let lhsOffset = calendar.dateComponents([.day], from: today, to: lhsDay).day ?? 0
        let rhsOffset = calendar.dateComponents([.day], from: today, to: rhsDay).day ?? 0

        let lhsDistance = abs(lhsOffset)
        let rhsDistance = abs(rhsOffset)

        if lhsDistance != rhsDistance {
            return lhsDistance < rhsDistance
        }

        if lhsDay != rhsDay {
            return lhsDay < rhsDay
        }

        return lhs.createdAt < rhs.createdAt
    }
}

// MARK: - Subviews
private extension NotebooksSheetView {
    var header: some View {
        HStack {
            SDSheetTitleView(iconSystemName: "list.bullet", title: "事件本")
            
            // badge
            Text("\(notebooks.count)")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .contentTransition(.numericText())
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(.quinary)
                )
            
            Spacer()
            
            Button {
                withAnimation(.spring(duration: 0.2)) {
                    isEditing.toggle()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: isEditing ? "checkmark" : "pencil")
                        .contentTransition(.symbolEffect)
                    
                    Text(isEditing ? "完成" : "编辑")
                        .contentTransition(.numericText())
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(.quinary)
                )
            }
            .buttonStyle(.plain)
        }
    }

    var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "books.vertical")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.secondary)

            Text("还没有事件本")
                .font(.headline)

            Text("先创建一个事件本，后面再接入完整的创建和编辑流程。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    var footer: some View {
        HStack {
            Button(action: onBack) {
                SDSheetActionButton(
                    iconSystemName: "arrow.left",
                    title: "返回",
                    placement: .left,
                    style: .plain
                )
            }
            .buttonStyle(.plain)

            Button(action: onCreateNotebook) {
                SDSheetActionButton(
                    iconSystemName: "plus",
                    title: "新建",
                    placement: .right,
                    style: .prominent
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 5)
    }

    func handleAccessoryTap(for notebook: Notebook) {
        if isEditing {
            onEditNotebook(notebook)
            return
        }

        onOpenNotebook(notebook)
    }
}

#Preview {
    NotebooksSheetView(onBack: {})
        .modelContainer(notebookListPreviewContainer)
        .padding()
}

private let notebookListPreviewContainer: ModelContainer = {
    let container = ModelContainerProvider.makePreviewContainer()
    let context = container.mainContext

    let lifeNotebook = Notebook(
        name: "生活",
        colorHex: "FF8A65",
        iconSystemName: "leaf.fill"
    )
    let workNotebook = Notebook(
        name: "工作",
        colorHex: "5C6BC0",
        iconSystemName: "briefcase.fill"
    )

    context.insert(lifeNotebook)
    context.insert(workNotebook)

    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)
    let offsets = [0, 2, 5, 12]

    for (index, offset) in offsets.enumerated() {
        let event = Event(
            title: "生活事件 \(index + 1)",
            targetDate: calendar.date(byAdding: .day, value: offset, to: today) ?? today,
            allDay: true,
            notebook: lifeNotebook
        )
        context.insert(event)
    }

    let archivedEvent = Event(
        title: "已归档事件",
        targetDate: today,
        allDay: true,
        notebook: workNotebook
    )
    archivedEvent.isArchived = true
    context.insert(archivedEvent)

    let workEvent = Event(
        title: "项目里程碑",
        targetDate: calendar.date(byAdding: .day, value: 1, to: today) ?? today,
        allDay: true,
        notebook: workNotebook
    )
    context.insert(workEvent)

    return container
}()
