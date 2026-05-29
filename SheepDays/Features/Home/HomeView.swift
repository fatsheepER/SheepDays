//
//  HomeView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import SwiftUI
import SwiftData
import Foundation

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.haptics) private var haptics
    @Environment(\.appOverlayCoordinator) private var overlayCoordinator

    @State private var referenceDate = HomeReferenceDate.normalized(.now)
    @State private var dateRestoreTask: Task<Void, Never>?
    @State private var dateRestoreToken = 0
    @State private var itemBadgeDisplayMode: HomeItemBadgeDisplayMode = .relativeText
    @State private var focusState = HomeFocusState()
    @State private var selectedFocusPresetID: UUID?
    @State private var hasRestoredLastFocusState = false

    @State private var isBottomSheetPresented = true
    @State private var sheetRoute: HomeSheetRoute = .home
    @State private var availableSheetDetents = HomeSheetDetents.home
    @State private var selectedSheetDetent = HomeSheetDetents.regular
    @State private var detentTransitionToken = 0
    @State private var contentRefreshToken = 0
    @State private var shouldFocusQuickAddTitle = false
    @State private var selectedEvent: Event?
    @State private var notebookEditorOption: NotebookEditorOption?

    var body: some View {
        NavigationStack {
            homeContent
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack {
                            Menu {
                                Section("Testing") {
                                    Button("Add Preview Events", action: insertPreviewEvents)
                                    Button("Clear Preview Events", role: .destructive, action: removePreviewEvents)
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }

                            Button {
                                showSettings()
                            } label: {
                                Image(systemName: "gear")
                            }
                        }
                    }
                }
                .onAppear {
                    isBottomSheetPresented = true
                    restoreLastFocusStateIfNeeded()
                }
                .onDisappear {
                    cancelDateRestore()
                }
                .sheet(isPresented: $isBottomSheetPresented) {
                    sheetContainer
                        .ignoresSafeArea()
                }
        }
    }
}

// MARK: - Main Content
private extension HomeView {
    // 让 HomeDateView 向上与 Toolbar 重叠
    static let homeContentToolbarOverlap: CGFloat = 40
    // 控制顶部柔化层效果
    static let floatingDateScrollInset: CGFloat = 106
    static let floatingDateFadeHeight: CGFloat = 200
    static let floatingDateFadeOffset: CGFloat = -42
    // 控制底部柔化层效果
    static let bottomScrollFadeHeight: CGFloat = 172
    static let bottomScrollFadeOffset: CGFloat = 64
    static let bottomSheetInsetHeight: CGFloat = 200
    static let edgeFadeHorizontalBleed: CGFloat = 42
    // 分步回到 today 动画
    static let todayRestoreStepDelay: Duration = .milliseconds(220)
    static let todayRestoreStepCount = 3
    static let todayRestoreMinimumSegmentedDayOffset = 10

    static let previewNotebookDefinitions: [(name: String, colorHex: String, iconSystemName: String)] = [
        ("Preview Inbox", "#FFB347", "tray.full.fill"),
        ("Preview Life", "#7EC8E3", "leaf.fill"),
        ("Preview Work", "#FF7A7A", "briefcase.fill")
    ]

    static let previewEventDayOffsets: [Int] = [
        0, 1, 2, 3, 5, 7, 10, 14, 21, 30,
        45, 60, 75, 90, 105, 120, 135, 150, 165, 180
    ]

    var homeContent: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ZStack(alignment: .top) {
                homeSectionsArea

                floatingDateHeader
                    .allowsHitTesting(false)
                    .zIndex(1)
            }
            .padding(.horizontal)
            .padding(.top, -Self.homeContentToolbarOverlap)
        }
    }

    var homeSectionsArea: some View {
        let _ = contentRefreshToken
        let snapshot = loadHomeSnapshot() // 读取快照 判断是否需要显示 Placeholder
        let sections = snapshot.sections
        let targetDatesByEventID = snapshot.targetDatesByEventID

        return ZStack {
            if sections.isEmpty {
                emptyHomePlaceholder
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ZStack(alignment: .bottom) {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            sectionList(
                                sections: sections,
                                targetDatesByEventID: targetDatesByEventID
                            )
                        }
                        .safeAreaInset(edge: .bottom) {
                            if isBottomSheetPresented {
                                VStack {
                                    Text("Sheep Days")
                                        .font(.system(size: 20, weight: .semibold, design: .serif))
                                        .foregroundStyle(Color(.tertiaryLabel))

                                    Text("Made with LOVE since Apr 15, 2026")
                                        .font(.system(size: 10, weight: .regular, design: .serif))
                                        .foregroundStyle(Color(.tertiaryLabel))
                                }
                                .frame(height: Self.bottomSheetInsetHeight)
                            }
                        }
                    }

                    if isBottomSheetPresented {
                        scrollEdgeFade(edge: .bottom)
                            .frame(height: Self.bottomScrollFadeHeight)
                            .padding(.horizontal, -Self.edgeFadeHorizontalBleed)
                            .offset(y: Self.bottomScrollFadeOffset)
                            .allowsHitTesting(false)
                            .zIndex(1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func sectionList(
        sections: [HomeSection],
        targetDatesByEventID: [UUID: Date]
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Color.clear.frame(height: Self.floatingDateScrollInset)

            ForEach(sections) { section in
                homeSection(
                    section,
                    targetDatesByEventID: targetDatesByEventID
                )
                .transition(.scale.combined(with: .blurReplace))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // 单个 section 的显示内容
    func homeSection(
        _ section: HomeSection,
        targetDatesByEventID: [UUID: Date]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title = section.title, !title.isEmpty {
                SectionHeaderView(title: title)
                    .padding(.horizontal)
            }

            VStack(spacing: 0) {
                ForEach(section.items) { item in
                    HomeDisplayItemRow(
                        item: item,
                        badgeDisplayMode: itemBadgeDisplayMode,
                        badgeDate: targetDatesByEventID[item.sourceEventId],
                        openDetail: { openEventDetail(for: item.sourceEventId) },
                        jumpToEventDate: {
                            jumpHomeDateIfPossible(targetDatesByEventID[item.sourceEventId])
                        }
                    )
                    .id(item.id)
                    .transition(.blurReplace.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(homeSectionBackground)
        }
    }

    var emptyHomePlaceholder: some View {
        VStack(spacing: 10) {
            ContentUnavailableView("没有可显示的事件", systemImage: "tray", description: Text("点击创建新事件，或调整你的聚焦配置"))
        }
    }

    var homeSectionBackground: some View {
        RoundedRectangle(cornerRadius: 35, style: .continuous)
            .foregroundStyle(Color(.systemBackground))
    }

    var floatingDateHeader: some View {
        ZStack(alignment: .topLeading) {
            scrollEdgeFade(edge: .top)
                .frame(height: Self.floatingDateFadeHeight)
                .padding(.horizontal, -Self.edgeFadeHorizontalBleed)
                .offset(y: Self.floatingDateFadeOffset)

            HomeDateView(referenceDate: referenceDate)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    func scrollEdgeFade(edge: VerticalEdge) -> some View {
        ZStack {
            Rectangle()
                .fill(.thickMaterial)

            Rectangle()
                .fill(Color(.systemGroupedBackground).opacity(0.78))
        }
        .compositingGroup()
        .mask(scrollEdgeFadeMask(edge: edge))
        .ignoresSafeArea(.container, edges: scrollEdgeIgnoredEdges(for: edge))
    }

    func scrollEdgeFadeMask(edge: VerticalEdge) -> LinearGradient {
        let stops: [Gradient.Stop]

        switch edge {
        case .top:
            stops = [
                .init(color: .black.opacity(1.00), location: 0.0),
                .init(color: .black.opacity(0.82), location: 0.68),
                .init(color: .black.opacity(0.28), location: 0.88),
                .init(color: .clear, location: 1.0)
            ]
        case .bottom:
            stops = [
                .init(color: .clear, location: 0.0),
                .init(color: .black.opacity(0.24), location: 0.24),
                .init(color: .black.opacity(0.76), location: 0.66),
                .init(color: .black.opacity(0.96), location: 1.0)
            ]
        }

        return LinearGradient(
            gradient: Gradient(stops: stops),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    func scrollEdgeIgnoredEdges(for edge: VerticalEdge) -> Edge.Set {
        switch edge {
        case .top:
            return .top
        case .bottom:
            return .bottom
        }
    }

    // MARK: - Debug Functions
    func loadHomeSnapshot() -> (sections: [HomeSection], targetDatesByEventID: [UUID: Date]) {
        do {
            let events = try modelContext.fetch(FetchDescriptor<Event>())
            let query = HomeQuery(
                referenceDate: referenceDate,
                notebookSourceFilter: focusState.notebookSourceFilter,
                tagSourceFilter: focusState.tagSourceFilter,
                timeRangeFilter: focusState.timeRange,
                groupingMode: focusState.groupingMode,
                sortingMode: focusState.sortMode,
                includeAllEvents: false
            )

            let sections = HomeBuilder.build(events: events, query: query)
                .filter { !$0.items.isEmpty }
            let targetDatesByEventID = Dictionary(
                uniqueKeysWithValues: events.map { ($0.id, $0.targetDate) }
            )

            return (sections, targetDatesByEventID)
        } catch {
            return ([], [:])
        }
    }

    func restoreLastFocusStateIfNeeded() {
        guard !hasRestoredLastFocusState else {
            return
        }

        hasRestoredLastFocusState = true

        guard let payload = LastFocusStateStore.shared.load() else {
            return
        }

        do {
            let notebooks = try modelContext.fetch(FetchDescriptor<Notebook>())
            let tags = try modelContext.fetch(FetchDescriptor<Tag>())

            if let presetID = payload.selectedPresetID,
               restoreLastFocusState(fromPresetID: presetID, notebooks: notebooks, tags: tags) {
                return
            }

            let resolution = payload.settings.resolved(notebooks: notebooks, tags: tags)
            focusState = resolution.focusState
            selectedFocusPresetID = nil
            LastFocusStateStore.shared.save(
                settings: resolution.prunedSettings,
                selectedPresetID: nil
            )
        } catch {
            assertionFailure("Failed to restore last focus state: \(error.localizedDescription)")
        }
    }

    func restoreLastFocusState(
        fromPresetID presetID: UUID,
        notebooks: [Notebook],
        tags: [Tag]
    ) -> Bool {
        do {
            let predicate = #Predicate<FocusPreset> { preset in
                preset.id == presetID
            }
            var descriptor = FetchDescriptor<FocusPreset>(predicate: predicate)
            descriptor.fetchLimit = 1

            guard let preset = try modelContext.fetch(descriptor).first else {
                return false
            }

            let settings = try preset.decodedSettings()
            let resolution = settings.resolved(notebooks: notebooks, tags: tags)

            if resolution.prunedSettings != settings {
                try preset.updateSettings(resolution.prunedSettings)
                try modelContext.save()
            }

            focusState = resolution.focusState
            selectedFocusPresetID = preset.id
            LastFocusStateStore.shared.save(
                settings: resolution.prunedSettings,
                selectedPresetID: preset.id
            )
            return true
        } catch {
            assertionFailure("Failed to restore focus preset: \(error.localizedDescription)")
            return false
        }
    }

    func insertPreviewEvents() {
        do {
            try removePreviewData()

            let notebooks = Self.previewNotebookDefinitions.map { definition in
                Notebook(
                    name: definition.name,
                    colorHex: definition.colorHex,
                    iconSystemName: definition.iconSystemName
                )
            }

            notebooks.forEach(modelContext.insert)

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: .now)
            let icons = [
                "calendar",
                "party.popper.fill",
                "airplane",
                "gift.fill",
                "star.fill"
            ]

            for (index, dayOffset) in Self.previewEventDayOffsets.enumerated() {
                guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                    continue
                }

                let notebook = notebooks[index % notebooks.count]
                let event = Event(
                    title: "Preview Event \(index + 1)",
                    note: "Temporary sample data for home layout testing.",
                    targetDate: targetDate,
                    allDay: true,
                    iconSystemName: icons[index % icons.count],
                    importanceLevel: index % 3,
                    showOnHome: true,
                    pinToTop: false,
                    notebook: notebook
                )

                modelContext.insert(event)
            }

            try modelContext.save()
            contentRefreshToken += 1
        } catch {
            assertionFailure("Failed to insert preview events: \(error.localizedDescription)")
        }
    }

    func removePreviewEvents() {
        do {
            try removePreviewData()
            try modelContext.save()
            contentRefreshToken += 1
        } catch {
            assertionFailure("Failed to remove preview events: \(error.localizedDescription)")
        }
    }

    func removePreviewData() throws {
        let events = try modelContext.fetch(FetchDescriptor<Event>())
        let notebooks = try modelContext.fetch(FetchDescriptor<Notebook>())
        let previewNotebookNames = Set(Self.previewNotebookDefinitions.map(\.name))

        for event in events where event.title.hasPrefix("Preview Event ") {
            modelContext.delete(event)
        }

        for notebook in notebooks where previewNotebookNames.contains(notebook.name) {
            modelContext.delete(notebook)
        }
    }

    // MARK: - Event Detail Functions
    func openEventDetail(for eventID: UUID) {
        haptics.play(.openDetailTap)
        withAnimation {
            presentEventDetail(for: eventID)
        }
    }

    func presentEventDetail(for eventID: UUID) {
        do {
            let predicate = #Predicate<Event> { event in
                event.id == eventID
            }
            var descriptor = FetchDescriptor<Event>(predicate: predicate)
            descriptor.fetchLimit = 1
            if let event = try modelContext.fetch(descriptor).first {
                selectedEvent = event
                notebookEditorOption = nil
                sheetRoute = .eventDetail
            }
        } catch {
            assertionFailure("Failed to load event detail: \(error.localizedDescription)")
        }
    }

    func jumpHomeDateIfPossible(_ targetDate: Date?) {
        guard let targetDate else {
            return
        }

        jumpHomeDate(to: targetDate)
    }

    func jumpHomeDate(to date: Date) {
        cancelDateRestore()

        let normalizedDate = HomeReferenceDate.normalized(date)

        haptics.play(.selectionStep)
        withAnimation {
            referenceDate = normalizedDate
        }
    }

    func restoreHomeDateToToday(
        stepCount requestedStepCount: Int = Self.todayRestoreStepCount,
        stepDelay: Duration = Self.todayRestoreStepDelay,
        minimumSegmentedDayOffset: Int = Self.todayRestoreMinimumSegmentedDayOffset
    ) {
        dateRestoreTask?.cancel()
        dateRestoreToken += 1
        let restoreToken = dateRestoreToken

        let calendar = Calendar.current
        let targetDate = HomeReferenceDate.normalized(.now, calendar: calendar)
        let startDate = HomeReferenceDate.normalized(referenceDate, calendar: calendar)
        let dayOffset = calendar.dateComponents([.day], from: startDate, to: targetDate).day ?? 0

        guard dayOffset != 0 else {
            haptics.play(.error)
            referenceDate = targetDate
            dateRestoreTask = nil
            return
        }

        let totalDistance = abs(dayOffset)
        guard totalDistance >= max(minimumSegmentedDayOffset, 1) else {
            withAnimation {
                haptics.play(.selectionStep)
                referenceDate = targetDate
            }
            dateRestoreTask = nil
            return
        }

        let direction = dayOffset.signum()
        let stepCount = min(totalDistance, max(requestedStepCount, 1))
        let stepDates = (1...stepCount).compactMap { stepIndex in
            let progress = Double(stepIndex) / Double(stepCount)
            let stepDistance = Int((Double(totalDistance) * progress).rounded()) * direction
            return calendar.date(byAdding: .day, value: stepDistance, to: startDate)
        }

        dateRestoreTask = Task { @MainActor in
            for stepIndex in stepDates.indices {
                guard restoreToken == dateRestoreToken, !Task.isCancelled else {
                    return
                }

                withAnimation {
                    haptics.play(.selectionStep)
                    referenceDate = stepDates[stepIndex]
                }

                guard stepIndex < stepDates.index(before: stepDates.endIndex) else {
                    continue
                }

                do {
                    try await Task.sleep(for: stepDelay)
                } catch {
                    return
                }
            }

            guard restoreToken == dateRestoreToken else {
                return
            }

            dateRestoreTask = nil
        }
    }

    func cancelDateRestore() {
        dateRestoreTask?.cancel()
        dateRestoreTask = nil
        dateRestoreToken += 1
    }

    var interactiveReferenceDate: Binding<Date> {
        Binding(
            get: { referenceDate },
            set: { newValue in
                cancelDateRestore()
                referenceDate = HomeReferenceDate.normalized(newValue)
            }
        )
    }

    func dismissEventDetail() {
        haptics.play(.openDetailTap)
        withAnimation(.spring(duration: 0.2)) {
            sheetRoute = .home
            selectedEvent = nil
            notebookEditorOption = nil
        }
        refreshHomeContent()
    }

    func refreshHomeContent() {
        contentRefreshToken += 1
    }

    func dismissNotebookEditor() {
        haptics.play(.openDetailTap)
        withAnimation(.spring(duration: 0.2)) {
            notebookEditorOption = nil
            sheetRoute = .notebooks
        }
        refreshHomeContent()
    }

    func presentSymbolPicker(_ presentation: SymbolPickerPresentation) {
        haptics.play(.openDetailTap)
        overlayCoordinator.present(
            .symbolPicker(
                presentation: presentation,
                onDismiss: handleSymbolPickerDismissed
            )
        )
    }

    func presentTagList(_ presentation: TagListPresentation) {
        haptics.play(.openDetailTap)
        overlayCoordinator.present(
            .tagList(
                presentation: presentation,
                onDismiss: handleTagListDismissed
            )
        )
    }

    func handleSymbolPickerDismissed() {
        haptics.play(.openDetailTap)
    }

    func handleTagListDismissed() {
        haptics.play(.openDetailTap)
        refreshHomeContent()
    }
}

// MARK: - Sheet Container
private extension HomeView {
    var sheetContainer: some View {
        VStack(spacing: 0) {
            sheetContent
        }
        .presentationDetents(availableSheetDetents, selection: $selectedSheetDetent)
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
        .presentationBackgroundInteraction(.enabled)
        .interactiveDismissDisabled()
        .padding(15)
        .animation(.snappy(duration: 0.25), value: sheetRoute)
        .onChange(of: sheetRoute) { _, newValue in
            transitionDetent(to: newValue)
        }
    }

    @ViewBuilder
    var sheetContent: some View {
        switch sheetRoute {
        case .home:
            HomeSheetView(
                referenceDate: interactiveReferenceDate,
                badgeDisplayMode: itemBadgeDisplayMode,
                isCompact: selectedSheetDetent == HomeSheetDetents.compact,
                onTapFocus: { showFocus() },
                onTapQuickAdd: { showQuickAdd() },
                onTapNotebooks: { showNotebooks() },
                onTapSettings: { showSettings() },
                onTapToday: {
                    restoreHomeDateToToday(stepCount: 3, minimumSegmentedDayOffset: 10)
                },
                onToggleBadgeDisplayMode: {
                    haptics.play(.openDetailTap)
                    withAnimation(.bouncy(duration: 0.2)) {
                        itemBadgeDisplayMode.toggle()
                    }
                }
            )
                .transition(.blurReplace)

        case .focus:
            FocusSheetView(
                focusState: $focusState,
                selectedPresetID: $selectedFocusPresetID,
                onBack: {
                    haptics.play(.openDetailTap)
                    showHomeSheet()
                }
            )
            .transition(.blurReplace)

        case .quickAdd:
            QuickAddSheetView(
                shouldAutoFocusTitle: shouldFocusQuickAddTitle,
                onCreate: { _ in
                    contentRefreshToken += 1
                    showHomeSheet()
                },
                onCancel: {
                    showHomeSheet()
                },
                onRequestSymbolPicker: presentSymbolPicker(_:),
                onRequestTagList: presentTagList(_:)
            )
            .transition(.blurReplace)

        case .notebooks:
            NotebooksSheetView(
                onBack: {
                    haptics.play(.openDetailTap)
                    showHomeSheet()
                },
                onCreateNotebook: { showNotebookCreator() },
                onEditNotebook: { notebook in
                    showNotebookEditor(for: notebook)
                },
                onOpenNotebook: { notebook in
                    showNotebookDetail(for: notebook)
                }
            )
            .transition(.blurReplace)

        case .notebookEditor:
            if let notebookEditorOption {
                NotebookEditorView(
                    option: notebookEditorOption,
                    onClose: dismissNotebookEditor,
                    onNotebookUpdated: refreshHomeContent,
                    onRequestSymbolPicker: presentSymbolPicker(_:)
                )
                .transition(.blurReplace)
            } else {
                SheetPlaceholderPage(
                    title: "Notebook",
                    onBack: { showNotebooks() }
                )
                .transition(.opacity)
            }

        case .settings:
            SheetPlaceholderPage(
                title: "Settings",
                onBack: { showHomeSheet() }
            )
            .transition(.blurReplace)

        case .eventDetail:
            if let selectedEvent {
                EventDetailView(
                    event: selectedEvent,
                    onClose: dismissEventDetail,
                    onEventUpdated: refreshHomeContent,
                    onRequestSymbolPicker: presentSymbolPicker(_:),
                    onRequestTagList: presentTagList(_:)
                )
                .transition(.blurReplace)
            } else {
                SheetPlaceholderPage(
                    title: "Event",
                    onBack: { showHomeSheet() }
                )
                .transition(.opacity)
            }
        }
    }

    func changeDetent(for route: HomeSheetRoute) -> PresentationDetent {
        switch route {
        case .home:
            return HomeSheetDetents.regular
        case .focus:
            return .fraction(0.65)
        case .settings:
            return .height(190)
        case .notebooks:
            return .fraction(0.82)
        case .notebookEditor:
            return .height(190)
        case .quickAdd:
            return .height(240)
        case .eventDetail:
            return .fraction(0.82)
        }
    }

    func detents(for route: HomeSheetRoute) -> Set<PresentationDetent> {
        switch route {
        case .home:
            return HomeSheetDetents.home
        default:
            return [changeDetent(for: route)]
        }
    }

    func transitionDetent(to route: HomeSheetRoute) {
        let nextDetent = changeDetent(for: route)
        let currentDetent = selectedSheetDetent

        detentTransitionToken += 1
        let transitionToken = detentTransitionToken

        availableSheetDetents = [currentDetent, nextDetent]

        withAnimation(.spring(duration: 0.25)) {
            selectedSheetDetent = nextDetent
        }

        Task {
            try? await Task.sleep(for: .milliseconds(320))

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                guard transitionToken == detentTransitionToken else {
                    return
                }

                availableSheetDetents = detents(for: route)
            }
        }
    }
}

private enum HomeSheetDetents {
    static let compact: PresentationDetent = .height(70)
    static let regular: PresentationDetent = .height(190)
    static let home: Set<PresentationDetent> = [compact, regular]
}

private extension HomeItemBadgeDisplayMode {
    mutating func toggle() {
        switch self {
        case .relativeText:
            self = .date
        case .date:
            self = .relativeText
        }
    }
}

// MARK: - Routing
private extension HomeView {
    func showHomeSheet() {
        // haptics depends on caller
        withAnimation(.spring(duration: 0.2)) {
            shouldFocusQuickAddTitle = false
            selectedEvent = nil
            notebookEditorOption = nil
            sheetRoute = .home
        }
    }

    func showFocus() {
        haptics.play(.openDetailTap)
        selectedEvent = nil
        notebookEditorOption = nil
        sheetRoute = .focus
    }

    func showQuickAdd() {
        haptics.play(.openDetailTap)
        withAnimation(.spring(duration: 0.2)) {
            shouldFocusQuickAddTitle = true
            selectedEvent = nil
            notebookEditorOption = nil
            sheetRoute = .quickAdd
        }
    }

    func showNotebooks() {
        haptics.play(.openDetailTap)
        withAnimation {
            selectedEvent = nil
            notebookEditorOption = nil
            sheetRoute = .notebooks
        }
    }

    func showSettings() {
        selectedEvent = nil
        notebookEditorOption = nil
        sheetRoute = .settings
    }

    func showNotebookCreator() {
        haptics.play(.openDetailTap)
        withAnimation(.spring(duration: 0.2)) {
            notebookEditorOption = .create
            selectedEvent = nil
            sheetRoute = .notebookEditor
        }
    }

    func showNotebookEditor(for notebook: Notebook) {
        haptics.play(.openDetailTap)
        withAnimation(.spring(duration: 0.2)) {
            notebookEditorOption = .edit(notebook)
            selectedEvent = nil
            sheetRoute = .notebookEditor
        }
    }

    func showNotebookDetail(for notebook: Notebook) {
        _ = notebook
        // Notebook detail feature will be wired here later.
    }
}

// MARK: - Route
private enum HomeSheetRoute {
    case home
    case focus
    case quickAdd
    case notebooks
    case notebookEditor
    case settings
    case eventDetail
}
#Preview {
    HomeView()
        .environment(\.appOverlayCoordinator, AppOverlayCoordinator())
        .modelContainer(ModelContainerProvider.makePreviewContainer())
}
