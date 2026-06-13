//
//  NotebookListView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import SwiftUI
import SwiftData

struct NotebooksSheetView: View {
    @Environment(\.haptics) private var haptics
    @Environment(\.modelContext) private var modelContext

    @State private var isEditing = false
    @State private var isShowingArchivedNotebooks = false
    @State private var selectedNotebook: Notebook?
    @State private var selectedNotebookSourceFrame: CGRect?
    @State private var isNotebookCardExpanded = false
    @State private var notebookCardFrames: [UUID: CGRect] = [:]
    @State private var notebookTransitionTask: Task<Void, Never>?
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

    var body: some View {
        rootContent
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
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
        .onDisappear {
            notebookTransitionTask?.cancel()
        }
    }
}

// MARK: - View State
private extension NotebooksSheetView {
    var rootContent: some View {
        GeometryReader { rootProxy in
            ZStack(alignment: .bottom) {
                VStack(spacing: 10) {
                    notebooksListPage
                        .allowsHitTesting(selectedNotebook == nil)
                        .accessibilityHidden(selectedNotebook != nil)

                    controls
                        .hidden()
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 5)
                .padding(.top, 5)

                if selectedNotebook != nil {
                    expandedNotebookCard(in: rootProxy)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                        .zIndex(1)
                }

                controls
                    .padding(.horizontal, 5)
                    .zIndex(2)
            }
            .frame(width: rootProxy.size.width, height: rootProxy.size.height)
            .onPreferenceChange(NotebookSummaryCardFramePreferenceKey.self) { frames in
                notebookCardFrames = frames
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

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

    var notebookZoomAnimation: Animation {
        .snappy(duration: 0.36, extraBounce: 0.02)
    }

    var selectedNotebookID: UUID? {
        selectedNotebook?.id
    }

    func activeNotebookCardID(for summary: NotebookSummary) -> String {
        "active-\(summary.id.uuidString)"
    }

    func archivedNotebookCardID(for summary: NotebookSummary) -> String {
        "archived-\(summary.id.uuidString)"
    }

    func makeSummary(for notebook: Notebook) -> NotebookSummary {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        let activeEvents = notebook.events
            .filter { event in
                !event.isArchived && event.notebook?.id == notebook.id
            }
            .sorted { lhs, rhs in
                notebookEventSort(lhs: lhs, rhs: rhs)
            }
        let eventDays = Set(activeEvents.map { calendar.startOfDay(for: $0.targetDate) })
        let futureEventCount = activeEvents.filter {
            calendar.startOfDay(for: $0.targetDate) > today
        }
        .count
        let pastEventCount = activeEvents.filter {
            calendar.startOfDay(for: $0.targetDate) < today
        }
        .count
        let upcomingEvents = activeEvents.filter {
            calendar.startOfDay(for: $0.targetDate) >= today
        }
        let weekEvents = upcomingEvents.filter {
            let eventDay = calendar.startOfDay(for: $0.targetDate)
            return eventDay <= weekEnd
        }

        return NotebookSummary(
            notebook: notebook,
            events: activeEvents,
            futureEventCount: futureEventCount,
            pastEventCount: pastEventCount,
            weekEvents: weekEvents,
            nextEvent: upcomingEvents.first,
            eventDays: eventDays,
            today: today
        )
    }

    func notebookEventSort(lhs: Event, rhs: Event) -> Bool {
        let calendar = Calendar.current
        let lhsDay = calendar.startOfDay(for: lhs.targetDate)
        let rhsDay = calendar.startOfDay(for: rhs.targetDate)

        if lhsDay != rhsDay {
            return lhsDay < rhsDay
        }

        return lhs.createdAt < rhs.createdAt
    }

}

// MARK: - Subviews
private extension NotebooksSheetView {
    func expandedNotebookCard(in rootProxy: GeometryProxy) -> some View {
        let frame = expandedNotebookCardFrame(in: rootProxy)

        return SDRoundedBackground(
            topLeading: 30,
            topTrailing: 30,
            bottomLeading: 30,
            bottomTrailing: 10,
            color: Color(.secondarySystemGroupedBackground)
        )
        .frame(width: frame.width, height: frame.height)
        .position(x: frame.midX, y: frame.midY)
    }

    func expandedNotebookCardFrame(in rootProxy: GeometryProxy) -> CGRect {
        let expandedFrame = CGRect(origin: .zero, size: rootProxy.size)

        guard !isNotebookCardExpanded,
              let sourceFrame = selectedNotebookSourceFrame else {
            return expandedFrame
        }

        let rootGlobalFrame = rootProxy.frame(in: .global)

        return CGRect(
            x: sourceFrame.minX - rootGlobalFrame.minX,
            y: sourceFrame.minY - rootGlobalFrame.minY,
            width: sourceFrame.width,
            height: sourceFrame.height
        )
    }

    var notebooksListPage: some View {
        VStack(spacing: 10) {
            header

            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    var content: some View {
        if activeNotebookSummaries.isEmpty && !isEditing {
            emptyState
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 20) {
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

                                    openNotebookDetail(summary.notebook)
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
        HStack(spacing: 10) {
            SDSheetTitleView(iconSystemName: "list.bullet", title: "事件本")
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("\(activeNotebookSummaries.count)")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .contentTransition(.numericText())
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color(.quaternarySystemFill))
                )
        }
        .frame(height: 30)
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
            Button(action: handleLeadingControlTap) {
                SDSheetActionButton(
                    iconSystemName: "arrow.left",
                    title: "返回",
                    placement: .left,
                    appearance: .plain
                )
            }
            .buttonStyle(.plain)

            Button(action: handleTrailingControlTap) {
                trailingControlLabel
            }
            .buttonStyle(.plain)
        }
        .animation(.snappy(duration: 0.25), value: selectedNotebookID)
    }

    @ViewBuilder
    var trailingControlLabel: some View {
        if let selectedNotebook {
            SDSheetActionButton(
                iconSystemName: "pencil",
                title: "编辑",
                placement: .right,
                backgroundColor: selectedNotebook.tintColor.opacity(0.2),
                titleForegroundColor: selectedNotebook.tintColor
            )
        } else {
            SDSheetActionButton(
                iconSystemName: "plus",
                title: "新建事件本",
                placement: .right,
                appearance: .prominent
            )
        }
    }

    func openNotebookDetail(_ notebook: Notebook) {
        guard let sourceFrame = notebookCardFrames[notebook.id] else {
            return
        }

        haptics.play(.openDetailTap)
        notebookTransitionTask?.cancel()

        var transaction = Transaction()
        transaction.animation = nil

        withTransaction(transaction) {
            selectedNotebook = notebook
            selectedNotebookSourceFrame = sourceFrame
            isNotebookCardExpanded = false
        }

        notebookTransitionTask = Task { @MainActor in
            await Task.yield()

            guard selectedNotebook?.id == notebook.id else {
                return
            }

            withAnimation(notebookZoomAnimation) {
                isNotebookCardExpanded = true
            }
        }
    }

    func closeNotebookDetail() {
        guard let selectedNotebook else {
            return
        }

        haptics.play(.openDetailTap)
        notebookTransitionTask?.cancel()

        withAnimation(notebookZoomAnimation) {
            isNotebookCardExpanded = false
        }

        let closingNotebookID = selectedNotebook.id
        notebookTransitionTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(380))

            guard self.selectedNotebook?.id == closingNotebookID,
                  !isNotebookCardExpanded else {
                return
            }

            var transaction = Transaction()
            transaction.animation = nil

            withTransaction(transaction) {
                self.selectedNotebook = nil
                selectedNotebookSourceFrame = nil
            }
        }
    }

    func handleLeadingControlTap() {
        if selectedNotebook != nil {
            closeNotebookDetail()
            return
        }

        onBack()
    }

    func handleTrailingControlTap() {
        guard let selectedNotebook else {
            onCreateNotebook()
            return
        }

        onEditNotebook(selectedNotebook)
    }

    func handleActiveNotebookAccessoryTap(for notebook: Notebook) {
        if isEditing {
            onEditNotebook(notebook)
            return
        }

        openNotebookDetail(notebook)
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
