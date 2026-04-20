//
//  NotebookListView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import SwiftUI
import SwiftData

struct NotebooksSheetView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var isEditing = false
    @State private var isShowingArchivedNotebooks = false
    @State private var selectedArchivedNotebookForAction: Notebook?

    @Query(
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

            content

            controls
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .confirmationDialog(
            selectedArchivedNotebookForAction?.name ?? "管理已归档事件本",
            isPresented: archivedNotebookActionDialogIsPresented,
            presenting: selectedArchivedNotebookForAction
        ) { notebook in
            Button("取消归档") {
                unarchiveNotebook(notebook)
            }

            Button("删除", role: .destructive) {
                deleteArchivedNotebook(notebook)
            }

            Button("取消", role: .cancel) {
                selectedArchivedNotebookForAction = nil
            }
        } message: { notebook in
            Text("你可以取消归档这个事件本，或者连同其中的事件一起删除。")
        }
    }
}

// MARK: - View State
private extension NotebooksSheetView {
    var activeNotebookSummaries: [NotebookSummary] {
        notebooks
            .filter { !$0.isArchived }
            .map(makeSummary(for:))
    }

    var archivedNotebookSummaries: [NotebookSummary] {
        notebooks
            .filter { $0.isArchived }
            .map(makeSummary(for:))
    }

    var archivedToggleIconSystemName: String {
        isShowingArchivedNotebooks ? "eye.slash" : "tray"
    }

    var archivedToggleTitle: String {
        isShowingArchivedNotebooks ? "隐藏" : "已归档"
    }

    var archivedNotebookActionDialogIsPresented: Binding<Bool> {
        Binding(
            get: { selectedArchivedNotebookForAction != nil },
            set: { isPresented in
                if !isPresented {
                    selectedArchivedNotebookForAction = nil
                }
            }
        )
    }

    func activeNotebookCardID(for summary: NotebookSummary) -> String {
        "active-\(summary.id.uuidString)"
    }

    func archivedNotebookCardID(for summary: NotebookSummary) -> String {
        "archived-\(summary.id.uuidString)"
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
    @ViewBuilder
    var content: some View {
        if activeNotebookSummaries.isEmpty && !isEditing {
            emptyState
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 15) {
                    if activeNotebookSummaries.isEmpty {
                        emptyStateCard
                    } else {
                        ForEach(activeNotebookSummaries) { summary in
                            NotebookSummaryCard(
                                summary: summary,
                                isEditing: isEditing,
                                onAccessoryTap: {
                                    handleActiveNotebookAccessoryTap(for: summary.notebook)
                                },
                                onTap: {
                                    guard !isEditing else {
                                        return
                                    }

                                    onOpenNotebook(summary.notebook)
                                }
                            )
                            .id(activeNotebookCardID(for: summary))
                        }
                        .transition(.move(edge: .trailing))
                    }

                    if isEditing {
                        archivedToggleButton

                        if isShowingArchivedNotebooks {
                            ForEach(archivedNotebookSummaries) { summary in
                                NotebookSummaryCard(
                                    summary: summary,
                                    isEditing: true,
                                    onAccessoryTap: {
                                        handleArchivedNotebookAccessoryTap(for: summary.notebook)
                                    },
                                    onTap: {}
                                )
                                .id(archivedNotebookCardID(for: summary))
                                .transition(.move(edge: .trailing))
                            }
                        }
                    }
                }
            }
        }
    }

    var header: some View {
        HStack {
            SDSheetTitleView(iconSystemName: "list.bullet", title: "事件本")
            
            // badge
            Text("\(activeNotebookSummaries.count)")
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
                    if !isEditing {
                        isShowingArchivedNotebooks = false
                    }
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

    var emptyStateCard: some View {
        emptyStateContent
            .frame(maxWidth: .infinity)
            .frame(minHeight: 220)
            .padding(24)
    }

    var emptyState: some View {
        emptyStateContent
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    var archivedToggleButton: some View {
        Button {
            withAnimation(.spring(duration: 0.2)) {
                isShowingArchivedNotebooks.toggle()
            }
        } label: {
            HStack {
                Image(systemName: archivedToggleIconSystemName)
//                    .contentTransition(.symbolEffect)

                Text(archivedToggleTitle)

//                Spacer()
            }
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Color(.secondaryLabel))
            .padding(10)
        }
        .buttonStyle(.plain)
    }

    var emptyStateContent: some View {
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
    }

    var controls: some View {
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

    func handleActiveNotebookAccessoryTap(for notebook: Notebook) {
        if isEditing {
            onEditNotebook(notebook)
            return
        }

        onOpenNotebook(notebook)
    }

    func handleArchivedNotebookAccessoryTap(for notebook: Notebook) {
        selectedArchivedNotebookForAction = notebook
    }

    func unarchiveNotebook(_ notebook: Notebook) {
        notebook.isArchived = false
        persistChanges(updating: notebook)
    }

    func deleteArchivedNotebook(_ notebook: Notebook) {
        let notebookEvents = notebook.events

        for event in notebookEvents {
            modelContext.delete(event)
        }

        modelContext.delete(notebook)
        persistChanges()
    }

    func persistChanges(updating notebook: Notebook? = nil) {
        if let notebook {
            notebook.updatedAt = .now
        }

        do {
            try modelContext.save()
            selectedArchivedNotebookForAction = nil
        } catch {
            assertionFailure("Failed to persist notebook changes: \(error.localizedDescription)")
        }
    }
}

#Preview {
    NotebooksSheetView(onBack: {})
        .modelContainer(notebookListPreviewContainer)
        .padding()
        .background(
            Color(.secondarySystemBackground)
                .ignoresSafeArea()
        )
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
    let archivedNotebook = Notebook(
        name: "归档项目",
        colorHex: "8E8E93",
        iconSystemName: "archivebox.fill",
        isArchived: true
    )

    context.insert(lifeNotebook)
    context.insert(workNotebook)
    context.insert(archivedNotebook)

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

    let archivedNotebookEvent = Event(
        title: "旧活动回顾",
        targetDate: calendar.date(byAdding: .day, value: -6, to: today) ?? today,
        allDay: true,
        notebook: archivedNotebook
    )
    context.insert(archivedNotebookEvent)

    return container
}()
