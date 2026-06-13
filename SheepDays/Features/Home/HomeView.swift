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
    @Environment(\.modelContext) var modelContext
    @Environment(\.haptics) var haptics
    @Environment(\.appOverlayCoordinator) var overlayCoordinator

    @State var referenceDate = HomeReferenceDate.normalized(.now)
    @State var dateRestoreTask: Task<Void, Never>?
    @State var dateRestoreToken = 0
    @State var itemBadgeDisplayMode: HomeItemBadgeDisplayMode = .relativeText
    @State var homeFocusState = HomeFocusState()
    @State var homeSelectedFocusPresetID: UUID?
    @State var memorialFocusState = HomeFocusState.memorialDefault
    @State var memorialSelectedFocusPresetID: UUID?
    @State var hasRestoredLastFocusStates = false

    @State var isBottomSheetPresented = true
    @State var sheetRoute: HomeSheetRoute = .home
    @State var availableSheetDetents = HomeSheetDetents.home
    @State var selectedSheetDetent = HomeSheetDetents.regular
    @State var detentTransitionToken = 0
    @State var contentRefreshToken = 0
    @State var shouldFocusQuickAddTitle = false
    @State var selectedEvent: Event?
    @State var selectedNotebook: Notebook?
    @State var notebookEditorOption: NotebookEditorOption?
    @State var activeHomeContentPage: HomeContentPage? = .upcoming
    @State var activeHomeThemeKind: HomeThemeKind = .standard
    @State var suppressHomeRowActions = false
    @State var rowActionSuppressionTask: Task<Void, Never>?
    @State var relativeValuePrompt: HomeRelativeValuePrompt?
    @State var relativeValueInput = ""

    var body: some View {
        homeContent
            .sheepDaysTheme(activeHomeTheme)
            .onAppear {
                isBottomSheetPresented = true
                restoreLastFocusStatesIfNeeded()
            }
            .onDisappear {
                cancelDateRestore()
                cancelHomeRowActionSuppression()
            }
            .sheet(isPresented: $isBottomSheetPresented) {
                sheetContainer
                    .sheepDaysTheme(activeHomeTheme)
                    .ignoresSafeArea()
            }
    }
}

// MARK: - Main Content
extension HomeView {
    // 控制顶部柔化层效果
    static let floatingDateFadeHeight: CGFloat = 150
    static let floatingDateFadeOffset: CGFloat = -35
    static let edgeFadeHorizontalBleed: CGFloat = 42
    static let homePageDragSuppressionDistance: CGFloat = 8
    static let homePageDragSuppressionDominance: CGFloat = 1.15
    static let homePageDragSuppressionResetDelay: Duration = .milliseconds(180)
    static let homeThemeTransitionAnimation = Animation.easeInOut(duration: 0.24)
    // 分步回到 today 动画
    static let todayRestoreStepDelay: Duration = .milliseconds(220)
    static let todayRestoreStepCount = 3
    static let todayRestoreMinimumSegmentedDayOffset = 10

    var homeContent: some View {
        ZStack(alignment: .topTrailing) {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ZStack(alignment: .top) {
                homePagesArea

                floatingDateHeader
                    .zIndex(1)
                    .padding(.horizontal)
                    .padding(.top)
            }

            HomeFloatingToolbar(
                onAddPreviewEvents: insertPreviewEvents,
                onClearPreviewEvents: removePreviewEvents,
                onOpenSettings: showSettings
            )
            .padding(.top)
            .padding(.trailing)
            .zIndex(2)
        }
    }

    var activeHomeTheme: SheepDaysTheme {
        activeHomeThemeKind.theme
    }

    var homePagesArea: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    memorialSectionsArea
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .id(HomeContentPage.expiredMemorials)

                    homeSectionsArea
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .id(HomeContentPage.upcoming)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $activeHomeContentPage)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .simultaneousGesture(homePageDragGesture)
            .onChange(of: activeHomeContentPage) { oldValue, newValue in
                guard let newValue, oldValue != newValue else {
                    return
                }

                transitionHomeTheme(to: newValue)

                if oldValue != nil {
                    haptics.play(.selectionStep)
                }
            }
        }
    }

    func transitionHomeTheme(to page: HomeContentPage) {
        let nextThemeKind = HomeThemeKind(page: page)

        guard activeHomeThemeKind != nextThemeKind else {
            return
        }

        withAnimation(Self.homeThemeTransitionAnimation) {
            activeHomeThemeKind = nextThemeKind
        }
    }

    var homeSectionsArea: some View {
        let _ = contentRefreshToken
        let snapshot = loadHomeSnapshot()

        return HomeSectionListView(
            sections: snapshot.sections,
            targetDatesByEventID: snapshot.targetDatesByEventID,
            badgeDisplayMode: itemBadgeDisplayMode,
            isBottomSheetPresented: isBottomSheetPresented,
            emptyContent: {
                emptyHomePlaceholder
            },
            openDetail: openEventDetailFromHomeRow(for:),
            jumpToEventDate: jumpHomeDateFromHomeRowIfPossible(_:),
            setRelativeValue: presentRelativeValuePromptFromHomeRowIfPossible(_:)
        )
    }

    var memorialSectionsArea: some View {
        let _ = contentRefreshToken
        let snapshot = loadMemorialSnapshot()

        return HomeSectionListView(
            sections: snapshot.sections,
            targetDatesByEventID: snapshot.targetDatesByEventID,
            badgeDisplayMode: itemBadgeDisplayMode,
            isBottomSheetPresented: isBottomSheetPresented,
            emptyContent: {
                emptyMemorialPlaceholder
            },
            openDetail: openEventDetailFromHomeRow(for:),
            jumpToEventDate: jumpHomeDateFromHomeRowIfPossible(_:),
            setRelativeValue: presentRelativeValuePromptFromHomeRowIfPossible(_:)
        )
    }

    var emptyHomePlaceholder: some View {
        VStack(spacing: 10) {
            ContentUnavailableView("没有可显示的事件", systemImage: "tray", description: Text("点击创建新事件，或调整你的聚焦配置"))
        }
    }

    var emptyMemorialPlaceholder: some View {
        VStack(spacing: 10) {
            ContentUnavailableView("没有可显示的纪念日", systemImage: "calendar.badge.clock")
        }
    }

    var floatingDateHeader: some View {
        ZStack(alignment: .topLeading) {
            HomeScrollEdgeFade(edge: .top)
                .frame(height: Self.floatingDateFadeHeight)
                .padding(.horizontal, -Self.edgeFadeHorizontalBleed)
                .offset(y: Self.floatingDateFadeOffset)
                .allowsHitTesting(false)

            HomeDateView(referenceDate: interactiveReferenceDate)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    var homePageDragGesture: some Gesture {
        DragGesture(minimumDistance: Self.homePageDragSuppressionDistance, coordinateSpace: .local)
            .onChanged { value in
                updateHomeRowActionSuppression(for: value)
            }
            .onEnded { _ in
                releaseHomeRowActionSuppressionAfterDelay()
            }
    }

    func updateHomeRowActionSuppression(for value: DragGesture.Value) {
        let horizontalDistance = abs(value.translation.width)
        let verticalDistance = abs(value.translation.height)

        guard horizontalDistance >= Self.homePageDragSuppressionDistance,
              horizontalDistance > verticalDistance * Self.homePageDragSuppressionDominance else {
            return
        }

        beginHomeRowActionSuppression()
    }

    func beginHomeRowActionSuppression() {
        rowActionSuppressionTask?.cancel()

        guard !suppressHomeRowActions else {
            return
        }

        suppressHomeRowActions = true
    }

    func releaseHomeRowActionSuppressionAfterDelay() {
        rowActionSuppressionTask?.cancel()
        rowActionSuppressionTask = Task { @MainActor in
            try? await Task.sleep(for: Self.homePageDragSuppressionResetDelay)

            guard !Task.isCancelled else {
                return
            }

            suppressHomeRowActions = false
            rowActionSuppressionTask = nil
        }
    }

    func cancelHomeRowActionSuppression() {
        rowActionSuppressionTask?.cancel()
        rowActionSuppressionTask = nil
        suppressHomeRowActions = false
    }
}

private let homePreviewContainer: ModelContainer = {
    let container = ModelContainerProvider.makePreviewContainer()

    do {
        try HomePreviewSupport.insertPreviewData(in: container.mainContext)
    } catch {
        assertionFailure("Failed to seed home preview data: \(error.localizedDescription)")
    }

    return container
}()

#Preview {
    HomeView()
        .environment(\.appOverlayCoordinator, AppOverlayCoordinator())
        .modelContainer(homePreviewContainer)
}
