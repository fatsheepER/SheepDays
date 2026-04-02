//
//  HomeView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var referenceDate = Calendar.current.startOfDay(for: .now)

    @State private var isBottomSheetPresented = true
    @State private var sheetRoute: HomeSheetRoute = .home
    @State private var contentRefreshToken = 0

    var body: some View {
        NavigationStack {
            homeContent
                .safeAreaInset(edge: .bottom) {
                    // 给主页主内容预留底部空间，避免被常驻 sheet 挡住
                    Color.clear
                        .frame(height: 170)
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
//                    .padding()
//                    .background(
//                        RoundedRectangle(cornerRadius: 25)
//                            .fill(Color(.secondarySystemFill))
//                    )
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        sectionList
                    }
                    .padding(.bottom)
                }
            }
            .padding(.horizontal)
        }
    }

    var sectionList: some View {
        let _ = contentRefreshToken
        let sections = loadSections()

        return VStack(alignment: .leading, spacing: 20) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 12) {
                    if sections.count > 1 {
                        SectionHeaderView(title: section.title)
                    }

                    VStack(spacing: 10) {
                        ForEach(section.items) { item in
                            HomeDisplayItemView(item: item)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func loadSections() -> [HomeSection] {
        do {
            let events = try modelContext.fetch(FetchDescriptor<Event>())
            let query = HomeQuery(
                referenceDate: referenceDate,
                includedNotebookIDs: [],
                includeAllEvents: false
            )

            return HomeBuilder.build(events: events, query: query)
                .filter { !$0.items.isEmpty }
        } catch {
            return []
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
                    tintHex: notebook.colorHex,
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
}

// MARK: - Sheet Container
private extension HomeView {
    var sheetContainer: some View {
        VStack(spacing: 0) {
            sheetContent
        }
        .presentationDetents([.height(190)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
        .presentationBackgroundInteraction(.enabled)
        .interactiveDismissDisabled()
        .padding(15)
        .animation(.snappy(duration: 0.25), value: sheetRoute)
    }

    @ViewBuilder
    var sheetContent: some View {
        switch sheetRoute {
        case .home:
            HomeSheetView(
                referenceDate: $referenceDate,
                onTapFocus: { showFocus() },
                onTapQuickAdd: { showQuickAdd() },
                onTapNotebooks: { showNotebooks() },
                onTapSettings: { showSettings() }) {
                    withAnimation {
                        referenceDate = Calendar.current.startOfDay(for: .now)
                    }
                }

        case .focus:
            SheetPlaceholderPage(
                title: "Focus",
                onBack: { showHomeSheet() }
            )

        case .quickAdd:
            SheetPlaceholderPage(
                title: "Quick Add",
                onBack: { showHomeSheet() }
            )

        case .notebooks:
            SheetPlaceholderPage(
                title: "Notebooks",
                onBack: { showHomeSheet() }
            )

        case .settings:
            SheetPlaceholderPage(
                title: "Settings",
                onBack: { showHomeSheet() }
            )
        }
    }
}

// MARK: - Routing
private extension HomeView {
    func showHomeSheet() {
        sheetRoute = .home
    }

    func showFocus() {
        sheetRoute = .focus
    }

    func showQuickAdd() {
        sheetRoute = .quickAdd
    }

    func showNotebooks() {
        sheetRoute = .notebooks
    }

    func showSettings() {
        sheetRoute = .settings
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
