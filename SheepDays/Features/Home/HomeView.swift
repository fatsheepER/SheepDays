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

    @State private var referenceDate = Calendar.current.startOfDay(for: .now)
    @State private var itemBadgeDisplayMode: HomeItemBadgeDisplayMode = .relativeText
    @State private var focusState = HomeFocusState()

    @State private var isBottomSheetPresented = true
    @State private var sheetRoute: HomeSheetRoute = .home
    @State private var availableSheetDetents: Set<PresentationDetent> = [.height(190)]
    @State private var selectedSheetDetent: PresentationDetent = .height(190)
    @State private var detentTransitionToken = 0
    @State private var contentRefreshToken = 0
    @State private var shouldFocusQuickAddTitle = false
    @State private var selectedEvent: Event?
    @State private var notebookEditorOption: NotebookEditorOption?
    @State private var symbolPickerPresentation: SymbolPickerPresentation?

    var body: some View {
        NavigationStack {
            homeContent
                .safeAreaInset(edge: .bottom) {
                    if isBottomSheetPresented {
                        // 给主页主内容预留底部空间，避免被常驻 sheet 挡住
                        Color.clear
                            .frame(height: 170)
                    }
                }
                .navigationTitle("Sheep Days")
                .navigationBarTitleDisplayMode(.inline)
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
//            Color(.systemGroupedBackground)
//                .ignoresSafeArea()
            VStack {
                HomeDateView(referenceDate: referenceDate)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        sectionList
                    }
                    .padding(.bottom)
                }
            }
            .padding(.horizontal)

            EventDetailOverlayView(
                event: selectedEvent,
                onClose: dismissEventDetail,
                onEventUpdated: refreshHomeContent,
                onRequestSymbolPicker: presentSymbolPicker(_:)
            )
            .zIndex(1)

            NotebookEditorOverlayView(
                option: notebookEditorOption,
                onClose: dismissNotebookEditor,
                onNotebookUpdated: refreshHomeContent,
                onRequestSymbolPicker: presentSymbolPicker(_:)
            )
            .zIndex(2)

            if let presentation = homeSymbolPickerPresentation {
                symbolPickerHost(for: presentation)
                    .zIndex(3)
            }
        }
        .animation(.snappy(duration: 0.3), value: selectedEvent != nil)
        .animation(.snappy(duration: 0.3), value: notebookEditorOption != nil)
        .animation(.snappy(duration: 0.3), value: homeSymbolPickerPresentation != nil)
    }

    var sectionList: some View {
        let _ = contentRefreshToken
        let snapshot = loadHomeSnapshot()
        let sections = snapshot.sections
        let targetDatesByEventID = snapshot.targetDatesByEventID

        return VStack(alignment: .leading, spacing: 20) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 12) {
                    if sections.count > 1 {
                        SectionHeaderView(title: section.title)
                    }

                    VStack(spacing: 5) {
                        ForEach(section.items) { item in
                            HomeDisplayItemView(
                                item: item,
                                badgeDisplayMode: itemBadgeDisplayMode,
                                badgeDate: targetDatesByEventID[item.sourceEventId],
                                onTap: {
                                    withAnimation {
                                        presentEventDetail(for: item.sourceEventId)
                                    }
                                }
                            )
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    func presentEventDetail(for eventID: UUID) {
        do {
            let predicate = #Predicate<Event> { event in
                event.id == eventID
            }
            var descriptor = FetchDescriptor<Event>(predicate: predicate)
            descriptor.fetchLimit = 1
            if let event = try modelContext.fetch(descriptor).first {
                isBottomSheetPresented = false
                selectedEvent = event
            }
        } catch {
            assertionFailure("Failed to load event detail: \(error.localizedDescription)")
        }
    }

    func dismissEventDetail() {
        withAnimation(.spring(duration: 0.2)) {
            selectedEvent = nil
            isBottomSheetPresented = true
        }
        refreshHomeContent()
    }

    func refreshHomeContent() {
        contentRefreshToken += 1
    }

    func dismissNotebookEditor() {
        withAnimation(.spring(duration: 0.2)) {
            notebookEditorOption = nil
            isBottomSheetPresented = true
        }
        refreshHomeContent()
    }

    func presentSymbolPicker(_ presentation: SymbolPickerPresentation) {
        symbolPickerPresentation = presentation
    }

    func dismissSymbolPicker() {
        symbolPickerPresentation = nil
    }

    var homeSymbolPickerPresentation: SymbolPickerPresentation? {
        isBottomSheetPresented ? nil : symbolPickerPresentation
    }

    var sheetSymbolPickerPresentation: SymbolPickerPresentation? {
        isBottomSheetPresented ? symbolPickerPresentation : nil
    }

    var sheetSymbolPickerBinding: Binding<SymbolPickerPresentation?> {
        Binding(
            get: { sheetSymbolPickerPresentation },
            set: { symbolPickerPresentation = $0 }
        )
    }

    @ViewBuilder
    func symbolPickerHost(for presentation: SymbolPickerPresentation) -> some View {
        SymbolPickerOverlayView(
            isPresented: true,
            title: presentation.title,
            sections: presentation.sections,
            selectedSystemName: presentation.selectedSystemName,
            tintColor: presentation.tintColor,
            presentationDelay: .zero,
            onSelect: presentation.onSelect,
            onClose: dismissSymbolPicker
        )
        .ignoresSafeArea()
    }

    @ViewBuilder
    func sheetSymbolPickerHost(for presentation: SymbolPickerPresentation) -> some View {
        SymbolPickerOverlayView(
            isPresented: true,
            title: presentation.title,
            sections: presentation.sections,
            selectedSystemName: presentation.selectedSystemName,
            tintColor: presentation.tintColor,
            presentationDelay: .milliseconds(180),
            onSelect: presentation.onSelect,
            onClose: dismissSymbolPicker
        )
        .presentationBackground(.clear)
        .ignoresSafeArea()
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
        .fullScreenCover(item: sheetSymbolPickerBinding) { presentation in
            sheetSymbolPickerHost(for: presentation)
        }
    }

    @ViewBuilder
    var sheetContent: some View {
        switch sheetRoute {
        case .home:
            HomeSheetView(
                referenceDate: $referenceDate,
                badgeDisplayMode: itemBadgeDisplayMode,
                onTapFocus: { showFocus() },
                onTapQuickAdd: { showQuickAdd() },
                onTapNotebooks: { showNotebooks() },
                onTapSettings: { showSettings() },
                onTapToday: {
                    withAnimation {
                        referenceDate = Calendar.current.startOfDay(for: .now)
                    }
                },
                onToggleBadgeDisplayMode: {
                    withAnimation(.bouncy(duration: 0.2)) {
                        itemBadgeDisplayMode.toggle()
                    }
                }
            )
                .transition(.opacity)

        case .focus:
            FocusSheetView(
                focusState: $focusState,
                onBack: { showHomeSheet() }
            )
            .transition(.opacity)

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
                onRequestSymbolPicker: presentSymbolPicker(_:)
            )
            .transition(.opacity)
//            .transition(.move(edge: .bottom).combined(with: .opacity))

        case .notebooks:
            NotebooksSheetView(
                onBack: { showHomeSheet() },
                onCreateNotebook: { showNotebookCreator() },
                onEditNotebook: { notebook in
                    showNotebookEditor(for: notebook)
                },
                onOpenNotebook: { notebook in
                    showNotebookDetail(for: notebook)
                }
            )
            .transition(.opacity)

        case .settings:
            SheetPlaceholderPage(
                title: "Settings",
                onBack: { showHomeSheet() }
            )
        }
    }

    func changeDetent(for route: HomeSheetRoute) -> PresentationDetent {
        switch route {
        case .home:
            return .height(190)
        case .focus:
            return .fraction(0.65)
        case .settings:
            return .height(190)
        case .notebooks:
            return .fraction(0.82)
        case .quickAdd:
            return .height(250)
        }
    }

    func detents(for route: HomeSheetRoute) -> Set<PresentationDetent> {
        [changeDetent(for: route)]
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

                availableSheetDetents = [nextDetent]
            }
        }
    }
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
        withAnimation(.spring(duration: 0.2)) {
            shouldFocusQuickAddTitle = false
            sheetRoute = .home
        }
    }

    func showFocus() {
        sheetRoute = .focus
    }

    func showQuickAdd() {
        withAnimation(.spring(duration: 0.2)) {
            shouldFocusQuickAddTitle = true
            sheetRoute = .quickAdd
        }
    }

    func showNotebooks() {
        withAnimation {
            sheetRoute = .notebooks
        }
    }

    func showSettings() {
        sheetRoute = .settings
    }

    func showNotebookCreator() {
        withAnimation(.spring(duration: 0.2)) {
            isBottomSheetPresented = false
            notebookEditorOption = .create
        }
    }

    func showNotebookEditor(for notebook: Notebook) {
        withAnimation(.spring(duration: 0.2)) {
            isBottomSheetPresented = false
            notebookEditorOption = .edit(notebook)
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
    case settings
}
#Preview {
    HomeView()
        .modelContainer(for: [Event.self, Notebook.self, Tag.self], inMemory: true)
}
