//
//  NotebookListView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import SwiftUI
import SwiftData

private struct SelectedNotebookCardHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat?

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue() ?? value
    }
}

private let notebookRootCoordinateSpaceName = "notebooks-sheet-root"
private let notebookContentBottomPadding: CGFloat = 75

private enum NotebookCardTransitionPhase: Equatable {
    case idle
    case openingPrepared
    case opening
    case presented
    case closingPrepared
    case closing
    case settling
}

struct NotebooksSheetView: View {
    @Environment(\.haptics) private var haptics
    @Environment(\.modelContext) private var modelContext

    @State private var isEditing = false
    @State private var isShowingArchivedNotebooks = false
    @State private var selectedNotebook: Notebook?
    @State private var notebookTransitionCardFrames: [UUID: CGRect] = [:]
    @State private var notebookTransitionPhase: NotebookCardTransitionPhase = .idle
    @State private var selectedNotebookCardDragOffset = 0.0
    @State private var selectedNotebookCardHeight: CGFloat?
    @State private var notebookCardFrames: [UUID: CGRect] = [:]
    @State private var expandedNotebookIDs: Set<UUID> = []
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
            resetNotebookCardPresentation()
        }
    }
}

// MARK: - View State
private extension NotebooksSheetView {
    var rootContent: some View {
        GeometryReader { rootProxy in
            ZStack(alignment: .bottom) {
                content
                    .padding(.horizontal, 5)
                    .allowsHitTesting(notebookListAllowsHitTesting)
                    .accessibilityHidden(!notebookListAllowsHitTesting)
                    .zIndex(0)

                if notebookShowsTransitionLayers {
                    notebookEventsPreviewSurface(in: rootProxy)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                        .zIndex(1)

                    notebookCardStack(in: rootProxy)
                        .zIndex(2)
                }

                controlsLayer
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
                    .zIndex(4)
            }
            .frame(width: rootProxy.size.width, height: rootProxy.size.height)
            .coordinateSpace(name: notebookRootCoordinateSpaceName)
            .onPreferenceChange(NotebookSummaryCardFramePreferenceKey.self) { frames in
                notebookCardFrames = frames
            }
            .onPreferenceChange(SelectedNotebookCardHeightPreferenceKey.self) { height in
                selectedNotebookCardHeight = height
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

    var notebookWalletAnimation: Animation {
        .snappy(duration: 0.42, extraBounce: 0.01)
    }

    var notebookCardDismissDragDistance: CGFloat {
        115
    }

    var notebookShowsTransitionLayers: Bool {
        selectedNotebook != nil && notebookTransitionPhase != .idle
    }

    var notebookListAllowsHitTesting: Bool {
        notebookTransitionPhase == .idle
    }

    var notebookTransitionUsesTargetFrames: Bool {
        switch notebookTransitionPhase {
        case .opening, .presented, .closingPrepared:
            return true
        case .idle, .openingPrepared, .closing, .settling:
            return false
        }
    }

    var notebookTransitionCardsShowEventPreview: Bool {
        switch notebookTransitionPhase {
        case .idle, .openingPrepared, .closing, .settling:
            return true
        case .opening, .presented, .closingPrepared:
            return false
        }
    }

    var selectedNotebookSourceCardIsHidden: Bool {
        selectedNotebook != nil && notebookTransitionPhase != .idle
    }

    var notebookHeaderOffset: CGFloat {
        notebookChromeOpacity == 0 ? -58 : 0
    }

    var notebookControlsOffset: CGFloat {
        notebookChromeOpacity == 0 ? 85 : 0
    }

    var notebookChromeOpacity: Double {
        switch notebookTransitionPhase {
        case .idle, .openingPrepared, .closing, .settling:
            return 1
        case .opening, .presented, .closingPrepared:
            return 0
        }
    }

    var notebookListOpacity: Double {
        switch notebookTransitionPhase {
        case .idle, .openingPrepared, .closingPrepared, .closing, .settling:
            return 1
        case .opening, .presented:
            return 0
        }
    }

    var notebookDetailBackdropOpacity: Double {
        switch notebookTransitionPhase {
        case .opening, .presented, .closingPrepared:
            return 1
        case .idle, .openingPrepared, .closing, .settling:
            return 0
        }
    }

    var notebookBackgroundCardsOpacity: Double {
        switch notebookTransitionPhase {
        case .openingPrepared, .opening:
            return 1
        case .idle, .presented, .closingPrepared, .closing, .settling:
            return 0
        }
    }

    var transitionNotebookSummaries: [NotebookSummary] {
        activeNotebookSummaries.filter { summary in
            notebookTransitionCardFrames[summary.id] != nil
        }
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
    @ViewBuilder
    func notebookCardStack(in rootProxy: GeometryProxy) -> some View {
        if let selectedNotebookID = selectedNotebook?.id {
            ZStack(alignment: .topLeading) {
                ForEach(Array(transitionNotebookSummaries.enumerated()), id: \.element.id) { visibleIndex, summary in
                    let frame = notebookStackFrame(
                        for: summary,
                        visibleIndex: visibleIndex,
                        in: rootProxy
                    )
                    let shadow = notebookStackShadow(for: summary)

                    NotebookSummaryCard(
                        summary: summary,
                        isEditing: false,
                        reportsFrame: false,
                        showsEventPreview: notebookTransitionCardsShowEventPreview,
                        isExpanded: notebookExpansionBinding(for: summary),
                        onAccessoryTap: {},
                        onTap: {}
                    )
                    .frame(width: frame.width, alignment: .top)
                    .background {
                        if summary.id == selectedNotebookID {
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: SelectedNotebookCardHeightPreferenceKey.self,
                                    value: proxy.size.height
                                )
                            }
                        }
                    }
                    .shadow(
                        color: .black.opacity(shadow.opacity),
                        radius: shadow.radius,
                        y: shadow.y
                    )
                    .contentShape(
                        SDRoundedCornersShape(
                            topLeading: 30,
                            topTrailing: 30,
                            bottomLeading: 30,
                            bottomTrailing: 10,
                            style: .continuous
                        )
                    )
                    .offset(x: frame.minX, y: frame.minY)
                    .opacity(notebookStackOpacity(for: summary))
                    .zIndex(notebookStackZIndex(for: summary, visibleIndex: visibleIndex))
                    .accessibilityHidden(summary.id != selectedNotebookID)
                }

                let selectedFrame = selectedNotebookCardTargetFrame(in: rootProxy)
                Color.clear
                    .frame(
                        width: selectedFrame.width,
                        height: selectedNotebookCardHeight ?? selectedFrame.height
                    )
                    .contentShape(Rectangle())
                    .offset(x: selectedFrame.minX, y: selectedFrame.minY)
                    .gesture(selectedNotebookCardDragGesture)
                    .zIndex(10_000)
                    .accessibilityAddTraits(.isButton)
            }
            .frame(width: rootProxy.size.width, height: rootProxy.size.height, alignment: .topLeading)
        }
    }

    @ViewBuilder
    func notebookEventsPreviewSurface(in rootProxy: GeometryProxy) -> some View {
        if selectedNotebook != nil {
            NotebookEventsPreviewSurface(
                topInset: selectedNotebookEventsSurfaceTopInset(in: rootProxy),
                horizontalInset: selectedNotebookCardTargetFrame(in: rootProxy).minX,
                opacity: notebookDetailBackdropOpacity
            )
            .animation(notebookWalletAnimation, value: selectedNotebookCardHeight)
        }
    }

    func notebookStackFrame(
        for summary: NotebookSummary,
        visibleIndex: Int,
        in rootProxy: GeometryProxy
    ) -> CGRect {
        notebookTransitionUsesTargetFrames
            ? notebookStackTargetFrame(for: summary, visibleIndex: visibleIndex, in: rootProxy)
            : notebookStackSourceFrame(for: summary, in: rootProxy)
    }

    func notebookStackSourceFrame(for summary: NotebookSummary, in rootProxy: GeometryProxy) -> CGRect {
        guard let frame = notebookTransitionCardFrames[summary.id] else {
            return .zero
        }

        return frame
    }

    func notebookStackTargetFrame(
        for summary: NotebookSummary,
        visibleIndex: Int,
        in rootProxy: GeometryProxy
    ) -> CGRect {
        let sourceFrame = notebookStackSourceFrame(for: summary, in: rootProxy)

        if summary.id == selectedNotebook?.id {
            var targetFrame = selectedNotebookCardTargetFrame(in: rootProxy)
            targetFrame.origin.y += selectedNotebookCardDragOffset
            return targetFrame
        }

        return notebookFrameBehindSelectedCard(
            forVisibleIndex: visibleIndex,
            fallbackFrame: sourceFrame,
            in: rootProxy
        )
    }

    func notebookFrameBehindSelectedCard(
        forVisibleIndex visibleIndex: Int,
        fallbackFrame: CGRect,
        in rootProxy: GeometryProxy
    ) -> CGRect {
        var selectedTargetFrame = selectedNotebookCardTargetFrame(in: rootProxy)
        let stackIndex = notebookBackgroundStackIndex(forVisibleIndex: visibleIndex)
        selectedTargetFrame.origin.y += CGFloat(stackIndex + 1) * 8

        return CGRect(
            x: selectedTargetFrame.minX,
            y: selectedTargetFrame.minY,
            width: selectedTargetFrame.width,
            height: fallbackFrame.height
        )
    }

    func notebookBackgroundStackIndex(forVisibleIndex visibleIndex: Int) -> Int {
        let previousSummaries = transitionNotebookSummaries.prefix(visibleIndex)
        let selectedCorrection = previousSummaries.contains { $0.id == selectedNotebook?.id } ? 1 : 0

        return visibleIndex - selectedCorrection
    }

    func notebookStackOpacity(for summary: NotebookSummary) -> Double {
        summary.id == selectedNotebook?.id ? 1 : notebookBackgroundCardsOpacity
    }

    func notebookStackShadow(for summary: NotebookSummary) -> (opacity: Double, radius: CGFloat, y: CGFloat) {
        guard notebookTransitionUsesTargetFrames else {
            return (0, 0, 0)
        }

        if summary.id == selectedNotebook?.id {
            return (0.08, 18, 10)
        }

        return (0.04 * notebookBackgroundCardsOpacity, 10, 4)
    }

    func notebookStackZIndex(for summary: NotebookSummary, visibleIndex: Int) -> Double {
        if summary.id == selectedNotebook?.id {
            return 1_000
        }

        return Double(transitionNotebookSummaries.count - visibleIndex)
    }

    func selectedNotebookCardSourceFrame(in rootProxy: GeometryProxy) -> CGRect {
        guard let selectedNotebook,
              let frame = notebookTransitionCardFrames[selectedNotebook.id] else {
            return .zero
        }

        return frame
    }

    func selectedNotebookCardTargetFrame(in rootProxy: GeometryProxy) -> CGRect {
        let sourceFrame = selectedNotebookCardSourceFrame(in: rootProxy)
        let topInset = max(5, rootProxy.safeAreaInsets.top + 5)

        return CGRect(
            x: sourceFrame.minX,
            y: topInset,
            width: sourceFrame.width,
            height: sourceFrame.height
        )
    }

    func selectedNotebookEventsSurfaceTopInset(in rootProxy: GeometryProxy) -> CGFloat {
        let targetFrame = selectedNotebookCardTargetFrame(in: rootProxy)
        let selectedCardHeight = selectedNotebookCardHeight ?? targetFrame.height

        return targetFrame.minY + selectedCardHeight + 15
    }

    @ViewBuilder
    var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 20) {
                scrollHeader

                if activeNotebookSummaries.isEmpty && !isEditing {
                    emptyState
                        .frame(minHeight: 360)
                } else {
                    if activeNotebookSummaries.isEmpty {
                        emptyStateCard
                    } else {
                        ForEach(activeNotebookSummaries) { summary in
                            activeNotebookCard(for: summary)
                        }
                        .transition(.move(edge: .trailing))
                    }

                    if isEditing {
                        archivedToggleButton

                        archivedNotebookCards
                    }
                }
            }
            .padding(.bottom, notebookContentBottomPadding)
            .opacity(notebookListOpacity)
        }
    }

    var scrollHeader: some View {
        header
            .padding(.top, 5)
            .padding(.horizontal, 5)
            .offset(y: notebookHeaderOffset)
            .opacity(notebookChromeOpacity)
    }

    func activeNotebookCard(for summary: NotebookSummary) -> some View {
        NotebookSummaryCard(
            summary: summary,
            isEditing: isEditing,
            frameCoordinateSpace: .named(notebookRootCoordinateSpaceName),
            isExpanded: notebookExpansionBinding(for: summary),
            onAccessoryTap: {
                handleActiveNotebookAccessoryTap(for: summary.notebook)
            },
            onTap: {
                guard !isEditing else {
                    return
                }

                openNotebookCard(summary.notebook)
            }
        )
        .id(activeNotebookCardID(for: summary))
        .opacity(notebookSourceCardOpacity(for: summary))
    }

    @ViewBuilder
    var archivedNotebookCards: some View {
        if isShowingArchivedNotebooks {
            ForEach(archivedNotebookSummaries) { summary in
                NotebookSummaryCard(
                    summary: summary,
                    isEditing: true,
                    frameCoordinateSpace: .named(notebookRootCoordinateSpaceName),
                    isExpanded: notebookExpansionBinding(for: summary),
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
        HStack(spacing: 10) {
            Spacer()

            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 15) {
                    HStack(spacing: 0) {
                        Button(action: handleBackControlTap) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 25))
                                .foregroundStyle(Color(.label))
                                .frame(width: 50, height: 50)
                                .padding(5)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("返回")

                        Button(action: handleEditModeControlTap) {
                            Image(systemName: "pencil")
                                .font(.system(size: 22))
                                .foregroundStyle(Color(.label))
                                .frame(width: 50, height: 50)
                                .padding(5)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isEditing ? "结束编辑" : "编辑事件本")
                    }
                    .glassEffect(.regular.interactive())

                    Button(action: handleCreateNotebookControlTap) {
                        Image(systemName: "plus")
                            .font(.system(size: 25))
                            .frame(width: 50, height: 50)
                            .padding(5)
                            .contentShape(Circle())
                            .glassEffect(.regular.tint(.accentColor.opacity(0.2)).interactive())
                    }
                    .accessibilityLabel("新建事件本")
                }
            }
        }
    }

    var controlsLayer: some View {
        controls
            .padding(.horizontal, 5)
            .offset(y: notebookControlsOffset)
            .opacity(notebookChromeOpacity)
            .allowsHitTesting(notebookListAllowsHitTesting)
            .accessibilityHidden(!notebookListAllowsHitTesting)
    }

    func notebookSourceCardOpacity(for summary: NotebookSummary) -> Double {
        guard selectedNotebookSourceCardIsHidden,
              summary.id == selectedNotebook?.id else {
            return 1
        }

        return 0
    }

    func notebookExpansionBinding(for summary: NotebookSummary) -> Binding<Bool> {
        Binding(
            get: {
                expandedNotebookIDs.contains(summary.id)
            },
            set: { isExpanded in
                if isExpanded {
                    expandedNotebookIDs.insert(summary.id)
                } else {
                    expandedNotebookIDs.remove(summary.id)
                }
            }
        )
    }

    var selectedNotebookCardDragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                guard selectedNotebook != nil,
                      notebookTransitionPhase == .presented else {
                    return
                }

                selectedNotebookCardDragOffset = rubberBandedNotebookCardDragOffset(
                    for: value.translation.height
                )
            }
            .onEnded { value in
                guard selectedNotebook != nil,
                      notebookTransitionPhase == .presented else {
                    return
                }

                if shouldDismissNotebookCard(for: value) {
                    closeNotebookCard()
                    return
                }

                withAnimation(notebookWalletAnimation) {
                    selectedNotebookCardDragOffset = 0
                }
            }
    }

    func rubberBandedNotebookCardDragOffset(for translation: CGFloat) -> CGFloat {
        if translation < 0 {
            return max(translation * 0.28, -45)
        }

        return min(translation, 260)
    }

    func shouldDismissNotebookCard(for value: DragGesture.Value) -> Bool {
        let downwardDistance = max(
            value.translation.height,
            value.predictedEndTranslation.height
        )

        return downwardDistance >= notebookCardDismissDragDistance
    }

    func openNotebookCard(_ notebook: Notebook) {
        guard let sourceFrame = notebookCardFrames[notebook.id] else {
            return
        }

        haptics.play(.openDetailTap)
        notebookTransitionTask?.cancel()

        var transaction = Transaction()
        transaction.animation = nil

        withTransaction(transaction) {
            selectedNotebook = notebook
            notebookTransitionCardFrames = notebookCardFrames
            notebookTransitionPhase = .openingPrepared
            selectedNotebookCardDragOffset = 0
            selectedNotebookCardHeight = sourceFrame.height
        }

        notebookTransitionTask = Task { @MainActor in
            await Task.yield()

            guard selectedNotebook?.id == notebook.id,
                  notebookTransitionPhase == .openingPrepared else {
                return
            }

            withAnimation(notebookWalletAnimation) {
                notebookTransitionPhase = .opening
            }

            try? await Task.sleep(for: .milliseconds(180))

            guard !Task.isCancelled,
                  selectedNotebook?.id == notebook.id,
                  notebookTransitionPhase == .opening else {
                return
            }

            withAnimation(.easeOut(duration: 0.16)) {
                notebookTransitionPhase = .presented
            }
        }
    }

    func closeNotebookCard() {
        guard let selectedNotebook else {
            return
        }

        haptics.play(.openDetailTap)
        notebookTransitionTask?.cancel()

        var transaction = Transaction()
        transaction.animation = nil

        withTransaction(transaction) {
            notebookTransitionPhase = .closingPrepared
        }

        withAnimation(notebookWalletAnimation) {
            notebookTransitionPhase = .closing
            selectedNotebookCardDragOffset = 0
        }

        let closingNotebookID = selectedNotebook.id
        notebookTransitionTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(430))

            guard self.selectedNotebook?.id == closingNotebookID,
                  notebookTransitionPhase == .closing else {
                return
            }

            var transaction = Transaction()
            transaction.animation = nil

            withTransaction(transaction) {
                notebookTransitionPhase = .settling
            }

            await Task.yield()

            guard self.selectedNotebook?.id == closingNotebookID,
                  notebookTransitionPhase == .settling else {
                return
            }

            withTransaction(transaction) {
                self.selectedNotebook = nil
                notebookTransitionCardFrames = [:]
                selectedNotebookCardHeight = nil
                selectedNotebookCardDragOffset = 0
                notebookTransitionPhase = .idle
            }
        }
    }

    func resetNotebookCardPresentation() {
        selectedNotebook = nil
        notebookTransitionCardFrames = [:]
        notebookTransitionPhase = .idle
        selectedNotebookCardDragOffset = 0
        selectedNotebookCardHeight = nil
    }

    func handleBackControlTap() {
        if selectedNotebook != nil {
            closeNotebookCard()
            return
        }

        onBack()
    }

    func handleEditModeControlTap() {
        withAnimation(.spring(duration: 0.2)) {
            isEditing.toggle()
        }
    }

    func handleCreateNotebookControlTap() {
        onCreateNotebook()
    }

    func handleActiveNotebookAccessoryTap(for notebook: Notebook) {
        if isEditing {
            onEditNotebook(notebook)
            return
        }

        openNotebookCard(notebook)
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

private struct NotebookEventsPreviewSurface: View {
    let topInset: CGFloat
    let horizontalInset: CGFloat
    let opacity: Double

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(height: max(220, proxy.size.height - topInset - 25))
                    .padding(.horizontal, max(5, horizontalInset))
                    .padding(.top, topInset)
                    .padding(.bottom, 25)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background(Color(.systemGroupedBackground))
        }
        .opacity(opacity)
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
