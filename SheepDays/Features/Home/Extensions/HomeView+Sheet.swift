//
//  HomeView+Sheet.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/6/12.
//

import SwiftUI

extension HomeView {
    var sheetContainer: some View {
        VStack(spacing: 0) {
            sheetContent
        }
        .presentationDetents(availableSheetDetents, selection: $selectedSheetDetent)
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
        .presentationBackgroundInteraction(sheetBackgroundInteraction)
        .interactiveDismissDisabled()
        .padding(15)
        .background(sheetContainerBackgroundColor.ignoresSafeArea(.all))
        .animation(.snappy(duration: 0.25), value: sheetRoute)
        .alert("设置相对数值", isPresented: relativeValuePromptIsPresented) {
            TextField("26, +26, -30", text: $relativeValueInput)
                .keyboardType(.numbersAndPunctuation)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Button("取消", role: .cancel) {
                clearRelativeValuePrompt()
            }

            Button("确定", action: applyRelativeValuePrompt)
                .disabled(parsedRelativeDayOffset == nil)
        }
        .onChange(of: sheetRoute) { _, newValue in
            transitionDetent(to: newValue)
        }
    }

    var sheetContainerBackgroundColor: Color {
        switch sheetRoute {
        case .eventDetail, .notebooks:
            return Color(.systemGroupedBackground)
        default:
            return Color.clear
        }
    }

    var sheetBackgroundInteraction: PresentationBackgroundInteraction {
        switch sheetRoute {
        case .focus, .quickAdd, .notebooks:
            return .disabled
        default:
            return .enabled
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
                focusState: activeFocusStateBinding,
                selectedPresetID: activeSelectedFocusPresetIDBinding,
                defaultFocusState: activeFocusDefaultState,
                lastFocusStateScope: activeFocusScope,
                onPresetDeleted: handleFocusPresetDeleted(_:),
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
            return .large
        case .notebookEditor:
            return .height(190)
        case .quickAdd:
            return .height(240)
        case .eventDetail:
            return .large
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

enum HomeSheetDetents {
    static let compact: PresentationDetent = .height(70)
    static let regular: PresentationDetent = .height(190)
    static let home: Set<PresentationDetent> = [compact, regular]
}
