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

private enum NotebookEditorOrigin: Equatable {
    case create
    case overview(UUID)
    case detail(UUID)
}

private enum NotebookEditorTransitionPhase: Equatable {
    case idle
    case prepared
    case stacking
    case presented
    case dismissing
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
    @State private var isShowingArchivedEvents = false
    @State private var notebookEditorOrigin: NotebookEditorOrigin?
    @State private var notebookEditorDraft = NotebookEditDraft.empty
    @State private var notebookEditorTransitionPhase: NotebookEditorTransitionPhase = .idle
    @State private var notebookEditorSourceFrame = CGRect.zero
    @State private var notebookEditorBackgroundCardFrames: [UUID: CGRect] = [:]
    @State private var notebookEditorTransitionTask: Task<Void, Never>?
    @State private var notebookRootSize = CGSize.zero
    @State private var notebookRootSafeAreaInsets = EdgeInsets()
    @State private var notebookEditorErrorMessage: String?
    @FocusState private var isNotebookEditorNameFocused: Bool

    @Query(
        sort: [
            SortDescriptor(\Notebook.updatedAt, order: .reverse),
            SortDescriptor(\Notebook.createdAt, order: .reverse)
        ]
    )
    private var notebooks: [Notebook]

    let onBack: () -> Void
    var onNotebookUpdated: () -> Void = {}
    var onRequestSymbolPicker: (SymbolPickerPresentation) -> Void = { _ in }

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
        .alert(
            "操作失败",
            isPresented: Binding(
                get: { notebookEditorErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        notebookEditorErrorMessage = nil
                    }
                }
            )
        ) {
            Button("确定", role: .cancel) {
                notebookEditorErrorMessage = nil
            }
        } message: {
            Text(notebookEditorErrorMessage ?? "未知错误")
        }
        .onDisappear {
            notebookTransitionTask?.cancel()
            notebookEditorTransitionTask?.cancel()
            resetNotebookCardPresentation()
            resetNotebookEditorPresentation()
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
                    .opacity(notebookEditorBackgroundOpacity)
                    .allowsHitTesting(notebookListAllowsHitTesting)
                    .accessibilityHidden(!notebookListAllowsHitTesting)
                    .zIndex(0)

                if notebookEditorUsesOverviewCardStack {
                    notebookEditorOverviewCardStack(in: rootProxy)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                        .zIndex(1)
                }

                if notebookShowsTransitionLayers {
                    notebookEventsPreviewSurface(in: rootProxy)
                        .opacity(notebookEditorBackgroundOpacity)
                        .allowsHitTesting(notebookDetailAllowsHitTesting)
                        .accessibilityHidden(!notebookDetailAllowsHitTesting)
                        .zIndex(1)

                    notebookCardStack(in: rootProxy)
                        .opacity(notebookEditorBackgroundOpacity)
                        .zIndex(2)
                }

                if notebookEditorOrigin != nil {
                    notebookEditorSurface(in: rootProxy)
                        .zIndex(3)
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
            .onAppear {
                notebookRootSize = rootProxy.size
                notebookRootSafeAreaInsets = rootProxy.safeAreaInsets
            }
            .onChange(of: rootProxy.size) { _, newSize in
                notebookRootSize = newSize
            }
            .onChange(of: rootProxy.safeAreaInsets) { _, newInsets in
                notebookRootSafeAreaInsets = newInsets
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
        notebookTransitionPhase == .idle && notebookEditorOrigin == nil
    }

    var notebookDetailAllowsHitTesting: Bool {
        notebookTransitionPhase == .presented && notebookEditorOrigin == nil
    }

    var notebookControlsAllowHitTesting: Bool {
        guard notebookEditorOrigin == nil else {
            return false
        }

        return notebookTransitionPhase == .idle || notebookTransitionPhase == .presented
    }

    var notebookEditorBackgroundOpacity: Double {
        if notebookEditorUsesOverviewCardStack {
            return 0
        }

        switch notebookEditorTransitionPhase {
        case .idle, .prepared, .stacking, .dismissing:
            return 1
        case .presented:
            return 0
        }
    }

    var notebookEditorUsesOverviewCardStack: Bool {
        guard selectedNotebook == nil,
              notebookEditorOrigin != nil else {
            return false
        }

        switch notebookEditorOrigin {
        case .create, .overview:
            return true
        case .detail, nil:
            return false
        }
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
        var summaries = activeNotebookSummaries.filter { summary in
            notebookTransitionCardFrames[summary.id] != nil
        }

        if let selectedNotebook,
           !summaries.contains(where: { $0.id == selectedNotebook.id }),
           notebookTransitionCardFrames[selectedNotebook.id] != nil {
            summaries.append(makeSummary(for: selectedNotebook))
        }

        return summaries
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
        if let selectedNotebook {
            NotebookEventsPreviewSurface(
                notebook: selectedNotebook,
                activeEvents: notebookEvents(in: selectedNotebook, isArchived: false),
                archivedEvents: notebookEvents(in: selectedNotebook, isArchived: true),
                isShowingArchivedEvents: $isShowingArchivedEvents,
                topInset: selectedNotebookEventsSurfaceTopInset(in: rootProxy),
                horizontalInset: selectedNotebookCardTargetFrame(in: rootProxy).minX,
                opacity: notebookDetailBackdropOpacity,
                onDeleteEvent: { _ in
                    // The first pass intentionally exposes only the destructive affordance.
                }
            )
            .animation(notebookWalletAnimation, value: selectedNotebookCardHeight)
        }
    }

    func notebookEvents(in notebook: Notebook, isArchived: Bool) -> [Event] {
        notebook.events
            .filter { event in
                event.isArchived == isArchived && event.notebook?.id == notebook.id
            }
            .sorted { lhs, rhs in
                notebookEventSort(lhs: lhs, rhs: rhs)
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

    func notebookEditorOverviewCardStack(in rootProxy: GeometryProxy) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(notebookEditorOverviewSummaries.enumerated()), id: \.element.id) { index, summary in
                let frame = notebookEditorOverviewFrame(
                    for: summary,
                    index: index,
                    in: rootProxy
                )

                NotebookSummaryCard(
                    summary: summary,
                    isEditing: false,
                    reportsFrame: false,
                    showsEventPreview: notebookEditorOverviewCardsShowEventPreview,
                    isExpanded: notebookExpansionBinding(for: summary),
                    onAccessoryTap: {},
                    onTap: {}
                )
                .frame(width: frame.width, alignment: .top)
                .shadow(
                    color: .black.opacity(notebookEditorOverviewCardShadowOpacity),
                    radius: 10,
                    y: 4
                )
                .offset(x: frame.minX, y: frame.minY)
                .opacity(notebookEditorOverviewCardStackOpacity)
                .zIndex(Double(notebookEditorOverviewSummaries.count - index))
            }
        }
        .frame(width: rootProxy.size.width, height: rootProxy.size.height, alignment: .topLeading)
    }

    var notebookEditorOverviewSummaries: [NotebookSummary] {
        activeNotebookSummaries.filter { summary in
            notebookEditorBackgroundCardFrames[summary.id] != nil
        }
    }

    var notebookEditorOverviewCardsShowEventPreview: Bool {
        notebookEditorTransitionPhase == .prepared
    }

    var notebookEditorOverviewCardStackOpacity: Double {
        notebookEditorTransitionPhase == .presented ? 0 : 1
    }

    var notebookEditorOverviewCardShadowOpacity: Double {
        switch notebookEditorTransitionPhase {
        case .stacking, .presented:
            return 0.04
        case .idle, .prepared, .dismissing:
            return 0
        }
    }

    func notebookEditorOverviewFrame(
        for summary: NotebookSummary,
        index: Int,
        in rootProxy: GeometryProxy
    ) -> CGRect {
        guard let sourceFrame = notebookEditorBackgroundCardFrames[summary.id] else {
            return .zero
        }

        guard notebookEditorTransitionPhase != .prepared else {
            return sourceFrame
        }

        let topFrame = notebookEditorTopFrame(in: rootProxy)

        return CGRect(
            x: topFrame.minX,
            y: topFrame.minY + CGFloat(index + 1) * 8,
            width: topFrame.width,
            height: sourceFrame.height
        )
    }

    func notebookEditorTopFrame(in rootProxy: GeometryProxy) -> CGRect {
        CGRect(
            x: notebookEditorSourceFrame.minX,
            y: max(5, rootProxy.safeAreaInsets.top + 5),
            width: notebookEditorSourceFrame.width,
            height: 130
        )
    }

    func notebookEditorSurface(in rootProxy: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            NotebookEditorControls(
                canSave: !notebookEditorDraft.trimmedName.isEmpty,
                onBack: dismissNotebookEditor,
                onSave: saveNotebookEditor
            )
            .opacity(notebookEditorControlsOpacity)

            NotebookEditorCard(
                draft: $notebookEditorDraft,
                nameFocus: $isNotebookEditorNameFocused,
                onRequestSymbolPicker: presentNotebookEditorSymbolPicker
            )
        }
        .padding(.horizontal, notebookEditorHorizontalInset)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .offset(y: notebookEditorSurfaceOffset(in: rootProxy))
        .accessibilityHidden(notebookEditorTransitionPhase == .dismissing)
    }

    var notebookEditorControlsOpacity: Double {
        notebookEditorTransitionPhase == .presented ? 1 : 0
    }

    var notebookEditorHorizontalInset: CGFloat {
        let sourceInset = notebookEditorSourceFrame.minX
        return sourceInset > 0 ? max(5, sourceInset) : 10
    }

    func notebookEditorSurfaceOffset(in rootProxy: GeometryProxy) -> CGFloat {
        switch notebookEditorTransitionPhase {
        case .presented:
            return 0
        case .prepared:
            let sourceMaxY = notebookEditorSourceFrame.maxY
            let fallbackMaxY = max(160, rootProxy.safeAreaInsets.top + 150)
            return -max(0, rootProxy.size.height - max(sourceMaxY, fallbackMaxY) - 10)
        case .idle, .stacking, .dismissing:
            let sourceMaxY = notebookEditorTopFrame(in: rootProxy).maxY
            let fallbackMaxY = max(160, rootProxy.safeAreaInsets.top + 150)
            return -max(0, rootProxy.size.height - max(sourceMaxY, fallbackMaxY) - 10)
        }
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
        GeometryReader { proxy in
            let progress = notebookDetailControlsProgress
            let overviewCapsuleOffset = max(
                0,
                proxy.size.width
                    - notebookToolbarPlusButtonWidth
                    - notebookToolbarGroupSpacing
                    - notebookToolbarOverviewCapsuleWidth
            )

            GlassEffectContainer(spacing: 10) {
                ZStack(alignment: .leading) {
                    notebookPrimaryControls(progress: progress)
                        .offset(x: overviewCapsuleOffset * (1 - progress))

                    notebookCreateControl
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(
                    width: proxy.size.width,
                    height: notebookToolbarButtonWidth,
                    alignment: .leading
                )
            }
        }
        .frame(height: notebookToolbarButtonWidth)
    }

    func notebookPrimaryControls(progress: CGFloat) -> some View {
        HStack(spacing: 0) {
            notebookToolbarButton(
                systemName: "chevron.left",
                fontSize: 25,
                accessibilityLabel: selectedNotebook == nil ? "返回" : "返回事件本列表",
                action: handleBackControlTap
            )

            notebookToolbarButton(
                systemName: "pencil",
                fontSize: 22,
                accessibilityLabel: notebookEditControlAccessibilityLabel,
                action: handleNotebookEditControlTap
            )

            notebookToolbarButton(
                systemName: "arrow.up.arrow.down",
                fontSize: 21,
                accessibilityLabel: "排序事件",
                action: {
                    // Sorting behavior is intentionally deferred.
                }
            )
            .frame(width: notebookToolbarButtonWidth * progress, alignment: .leading)
            .opacity(progress)
            .clipped()
            .allowsHitTesting(progress == 1)
            .accessibilityHidden(progress != 1)

            notebookMoreControl
                .frame(width: notebookToolbarButtonWidth * progress, alignment: .leading)
                .opacity(progress)
                .clipped()
                .allowsHitTesting(progress == 1)
                .accessibilityHidden(progress != 1)
        }
        .glassEffect(.regular.interactive())
    }

    var notebookMoreControl: some View {
        Menu {
            Button("归档事件本", systemImage: "archivebox") {
                // Notebook archiving behavior is intentionally deferred.
            }

            Button("删除事件本", systemImage: "trash", role: .destructive) {
                // Notebook deletion behavior is intentionally deferred.
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 22))
                .foregroundStyle(Color(.label))
                .frame(width: 50, height: 50)
                .padding(5)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("更多事件本操作")
    }

    var notebookCreateControl: some View {
        Button(action: handleCreateControlTap) {
            Image(systemName: "plus")
                .font(.system(size: 25))
                .frame(width: 50, height: 50)
                .padding(5)
                .contentShape(Circle())
                .glassEffect(.regular.tint(.accentColor.opacity(0.2)).interactive())
        }
        .accessibilityLabel(selectedNotebook == nil ? "新建事件本" : "在当前事件本中新建事件")
    }

    var notebookEditControlAccessibilityLabel: LocalizedStringKey {
        if selectedNotebook != nil {
            return "编辑事件本"
        }

        return isEditing ? "结束编辑" : "管理事件本"
    }

    var notebookDetailControlsProgress: CGFloat {
        switch notebookTransitionPhase {
        case .opening, .presented, .closingPrepared:
            return 1
        case .idle, .openingPrepared, .closing, .settling:
            return 0
        }
    }

    var notebookToolbarButtonWidth: CGFloat {
        60
    }

    var notebookToolbarOverviewCapsuleWidth: CGFloat {
        notebookToolbarButtonWidth * 2
    }

    var notebookToolbarPlusButtonWidth: CGFloat {
        60
    }

    var notebookToolbarGroupSpacing: CGFloat {
        15
    }

    func handleNotebookEditControlTap() {
        if selectedNotebook != nil {
            beginEditingSelectedNotebook()
        } else {
            handleEditModeControlTap()
        }
    }

    func handleCreateControlTap() {
        if selectedNotebook != nil {
            // Event creation behavior is intentionally deferred.
        } else {
            handleCreateNotebookControlTap()
        }
    }

    func notebookToolbarButton(
        systemName: String,
        fontSize: CGFloat,
        accessibilityLabel: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: fontSize))
                .foregroundStyle(Color(.label))
                .frame(width: 50, height: 50)
                .padding(5)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    var controlsLayer: some View {
        controls
            .padding(.horizontal, 5)
            .opacity(notebookEditorOrigin == nil ? 1 : 0)
            .allowsHitTesting(notebookControlsAllowHitTesting)
            .accessibilityHidden(!notebookControlsAllowHitTesting)
            .animation(notebookWalletAnimation, value: notebookTransitionPhase)
            .animation(.easeOut(duration: 0.18), value: notebookEditorOrigin)
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
                      notebookEditorOrigin == nil,
                      notebookTransitionPhase == .presented else {
                    return
                }

                selectedNotebookCardDragOffset = rubberBandedNotebookCardDragOffset(
                    for: value.translation.height
                )
            }
            .onEnded { value in
                guard selectedNotebook != nil,
                      notebookEditorOrigin == nil,
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
            isShowingArchivedEvents = false
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
        guard notebookEditorOrigin == nil,
              let selectedNotebook else {
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
                isShowingArchivedEvents = false
            }
        }
    }

    func resetNotebookCardPresentation() {
        selectedNotebook = nil
        notebookTransitionCardFrames = [:]
        notebookTransitionPhase = .idle
        selectedNotebookCardDragOffset = 0
        selectedNotebookCardHeight = nil
        isShowingArchivedEvents = false
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
        beginCreatingNotebook()
    }

    func handleActiveNotebookAccessoryTap(for notebook: Notebook) {
        if isEditing {
            beginEditingNotebookFromOverview(notebook)
            return
        }

        openNotebookCard(notebook)
    }

    func beginCreatingNotebook() {
        let sourceFrame = notebookEditorTopSourceFrame()
        let draft = NotebookEditDraft(
            sourceNotebookID: nil,
            name: "",
            iconSystemName: nil,
            colorHex: nil
        )

        beginNotebookEditor(
            origin: .create,
            draft: draft,
            sourceFrame: sourceFrame
        )
    }

    func beginEditingNotebookFromOverview(_ notebook: Notebook) {
        let sourceFrame = notebookCardFrames[notebook.id] ?? notebookEditorTopSourceFrame()

        beginNotebookEditor(
            origin: .overview(notebook.id),
            draft: notebookEditorDraft(for: notebook),
            sourceFrame: sourceFrame
        )
    }

    func beginEditingSelectedNotebook() {
        guard notebookTransitionPhase == .presented,
              let selectedNotebook else {
            return
        }

        beginNotebookEditor(
            origin: .detail(selectedNotebook.id),
            draft: notebookEditorDraft(for: selectedNotebook),
            sourceFrame: storedSelectedNotebookTargetFrame()
        )
    }

    func beginNotebookEditor(
        origin: NotebookEditorOrigin,
        draft: NotebookEditDraft,
        sourceFrame: CGRect
    ) {
        guard notebookEditorOrigin == nil else {
            return
        }

        haptics.play(.openDetailTap)
        notebookEditorTransitionTask?.cancel()
        let usesOverviewStack = notebookEditorOriginUsesOverviewStack(origin)

        var transaction = Transaction()
        transaction.animation = nil

        withTransaction(transaction) {
            notebookEditorDraft = draft
            notebookEditorSourceFrame = sourceFrame
            notebookEditorBackgroundCardFrames = usesOverviewStack ? notebookCardFrames : [:]
            notebookEditorOrigin = origin
            notebookEditorTransitionPhase = .prepared
            isNotebookEditorNameFocused = false
        }

        notebookEditorTransitionTask = Task { @MainActor in
            await Task.yield()

            guard notebookEditorOrigin == origin,
                  notebookEditorTransitionPhase == .prepared else {
                return
            }

            if usesOverviewStack {
                withAnimation(.snappy(duration: 0.34, extraBounce: 0.01)) {
                    notebookEditorTransitionPhase = .stacking
                }

                try? await Task.sleep(for: .milliseconds(210))

                guard !Task.isCancelled,
                      notebookEditorOrigin == origin,
                      notebookEditorTransitionPhase == .stacking else {
                    return
                }
            }

            withAnimation(.snappy(duration: 0.42, extraBounce: 0.01)) {
                notebookEditorTransitionPhase = .presented
            }

            try? await Task.sleep(for: .milliseconds(280))

            guard !Task.isCancelled,
                  notebookEditorOrigin == origin,
                  notebookEditorTransitionPhase == .presented else {
                return
            }

            isNotebookEditorNameFocused = true
        }
    }

    func notebookEditorOriginUsesOverviewStack(_ origin: NotebookEditorOrigin) -> Bool {
        switch origin {
        case .create, .overview:
            return true
        case .detail:
            return false
        }
    }

    func notebookEditorDraft(for notebook: Notebook) -> NotebookEditDraft {
        NotebookEditDraft(
            sourceNotebookID: notebook.id,
            name: notebook.name,
            iconSystemName: notebook.iconSystemName,
            colorHex: notebook.colorHex
        )
    }

    func notebookEditorTopSourceFrame() -> CGRect {
        let firstCardFrame = notebookCardFrames.values.min { lhs, rhs in
            lhs.minY < rhs.minY
        }
        let horizontalInset = firstCardFrame?.minX ?? 10
        let width = firstCardFrame?.width ?? max(0, notebookRootSize.width - horizontalInset * 2)
        let topInset = max(5, notebookRootSafeAreaInsets.top + 5)

        return CGRect(
            x: horizontalInset,
            y: topInset,
            width: width,
            height: 130
        )
    }

    func storedSelectedNotebookTargetFrame() -> CGRect {
        guard let selectedNotebook,
              let sourceFrame = notebookTransitionCardFrames[selectedNotebook.id] else {
            return notebookEditorTopSourceFrame()
        }

        return CGRect(
            x: sourceFrame.minX,
            y: max(5, notebookRootSafeAreaInsets.top + 5),
            width: sourceFrame.width,
            height: selectedNotebookCardHeight ?? sourceFrame.height
        )
    }

    func presentNotebookEditorSymbolPicker() {
        isNotebookEditorNameFocused = false

        onRequestSymbolPicker(
            SymbolPickerPresentation(
                title: "选择事件本图标",
                sections: SFSymbolLibrary.generalSections,
                selectedSystemName: notebookEditorDraft.iconSystemName,
                tintColor: notebookEditorDraft.tintColor,
                onSelect: { systemName in
                    notebookEditorDraft.iconSystemName = systemName
                }
            )
        )
    }

    func dismissNotebookEditor() {
        guard let origin = notebookEditorOrigin else {
            return
        }

        haptics.play(.openDetailTap)
        notebookEditorTransitionTask?.cancel()
        isNotebookEditorNameFocused = false

        if notebookEditorOriginUsesOverviewStack(origin) {
            dismissNotebookEditorToOverview(origin: origin)
            return
        }

        withAnimation(.snappy(duration: 0.38, extraBounce: 0)) {
            notebookEditorTransitionPhase = .dismissing
        }

        notebookEditorTransitionTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(390))

            guard !Task.isCancelled,
                  notebookEditorOrigin == origin,
                  notebookEditorTransitionPhase == .dismissing else {
                return
            }

            var transaction = Transaction()
            transaction.animation = nil

            withTransaction(transaction) {
                resetNotebookEditorPresentation()
            }
        }
    }

    func dismissNotebookEditorToOverview(origin: NotebookEditorOrigin) {
        withAnimation(.snappy(duration: 0.38, extraBounce: 0)) {
            notebookEditorTransitionPhase = .stacking
        }

        notebookEditorTransitionTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(240))

            guard !Task.isCancelled,
                  notebookEditorOrigin == origin,
                  notebookEditorTransitionPhase == .stacking else {
                return
            }

            withAnimation(.snappy(duration: 0.4, extraBounce: 0.01)) {
                notebookEditorTransitionPhase = .prepared
            }

            try? await Task.sleep(for: .milliseconds(410))

            guard !Task.isCancelled,
                  notebookEditorOrigin == origin,
                  notebookEditorTransitionPhase == .prepared else {
                return
            }

            var transaction = Transaction()
            transaction.animation = nil

            withTransaction(transaction) {
                resetNotebookEditorPresentation()
            }
        }
    }

    func saveNotebookEditor() {
        let name = notebookEditorDraft.trimmedName

        guard !name.isEmpty,
              let origin = notebookEditorOrigin else {
            return
        }

        haptics.play(.openDetailTap)

        switch origin {
        case .create:
            createNotebookFromDraft(name: name)
        case let .overview(notebookID), let .detail(notebookID):
            updateNotebookFromDraft(notebookID: notebookID, name: name)
        }
    }

    func createNotebookFromDraft(name: String) {
        let notebook = Notebook(
            name: name,
            colorHex: notebookEditorDraft.colorHex,
            iconSystemName: notebookEditorDraft.iconSystemName
        )
        modelContext.insert(notebook)

        do {
            try modelContext.save()
            onNotebookUpdated()
            transitionFromCreatedNotebookToDetail(notebook)
        } catch {
            modelContext.delete(notebook)
            notebookEditorErrorMessage = error.localizedDescription
        }
    }

    func updateNotebookFromDraft(notebookID: UUID, name: String) {
        guard let notebook = notebooks.first(where: { $0.id == notebookID })
                ?? (selectedNotebook?.id == notebookID ? selectedNotebook : nil) else {
            notebookEditorErrorMessage = "找不到需要编辑的事件本。"
            return
        }

        let originalName = notebook.name
        let originalIconSystemName = notebook.iconSystemName
        let originalColorHex = notebook.colorHex
        let originalUpdatedAt = notebook.updatedAt

        notebook.name = name
        notebook.iconSystemName = notebookEditorDraft.iconSystemName
        notebook.colorHex = notebookEditorDraft.colorHex
        notebook.updatedAt = .now

        do {
            try modelContext.save()
            onNotebookUpdated()
            dismissNotebookEditor()
        } catch {
            notebook.name = originalName
            notebook.iconSystemName = originalIconSystemName
            notebook.colorHex = originalColorHex
            notebook.updatedAt = originalUpdatedAt
            notebookEditorErrorMessage = error.localizedDescription
        }
    }

    func transitionFromCreatedNotebookToDetail(_ notebook: Notebook) {
        notebookEditorTransitionTask?.cancel()
        isNotebookEditorNameFocused = false

        var frames = notebookCardFrames
        frames[notebook.id] = notebookEditorSourceFrame

        var transaction = Transaction()
        transaction.animation = nil

        withTransaction(transaction) {
            selectedNotebook = notebook
            notebookTransitionCardFrames = frames
            notebookTransitionPhase = .presented
            selectedNotebookCardDragOffset = 0
            selectedNotebookCardHeight = notebookEditorSourceFrame.height
            isShowingArchivedEvents = false
        }

        withAnimation(.snappy(duration: 0.42, extraBounce: 0.01)) {
            notebookEditorTransitionPhase = .dismissing
        }

        notebookEditorTransitionTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(430))

            guard !Task.isCancelled,
                  selectedNotebook?.id == notebook.id else {
                return
            }

            var transaction = Transaction()
            transaction.animation = nil

            withTransaction(transaction) {
                resetNotebookEditorPresentation()
            }
        }
    }

    func resetNotebookEditorPresentation() {
        notebookEditorOrigin = nil
        notebookEditorDraft = .empty
        notebookEditorTransitionPhase = .idle
        notebookEditorSourceFrame = .zero
        notebookEditorBackgroundCardFrames = [:]
        isNotebookEditorNameFocused = false
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
    let notebook: Notebook
    let activeEvents: [Event]
    let archivedEvents: [Event]
    @Binding var isShowingArchivedEvents: Bool
    let topInset: CGFloat
    let horizontalInset: CGFloat
    let opacity: Double
    let onDeleteEvent: (Event) -> Void

    var body: some View {
        GeometryReader { proxy in
            NotebookDetailEventList(
                notebook: notebook,
                activeEvents: activeEvents,
                archivedEvents: archivedEvents,
                isShowingArchivedEvents: $isShowingArchivedEvents,
                onDeleteEvent: onDeleteEvent
            )
            .frame(height: max(220, proxy.size.height - topInset - 25))
            .padding(.horizontal, max(5, horizontalInset))
            .padding(.top, topInset)
            .padding(.bottom, 25)
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
