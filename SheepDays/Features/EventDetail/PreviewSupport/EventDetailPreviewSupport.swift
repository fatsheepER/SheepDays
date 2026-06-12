//
//  EventDetailPreviewSupport.swift
//  SheepDays
//
//  Created by Codex on 2026/6/12.
//

import SwiftUI
import SwiftData

struct EventDetailSheetPreviewHost: View {
    @Environment(\.haptics) private var haptics
    @StateObject private var overlayCoordinator = AppOverlayCoordinator()
    @State private var isBottomSheetPresented = true
    @State private var selectedSheetDetent: PresentationDetent = .large

    let event: Event

    var body: some View {
        NavigationStack {
            previewHomeContent
                .safeAreaInset(edge: .bottom) {
                    if isBottomSheetPresented {
                        Color.clear
                            .frame(height: 170)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                .sheet(isPresented: $isBottomSheetPresented) {
                    sheetContainer
                        .ignoresSafeArea()
                }
        }
        .environment(\.appOverlayCoordinator, overlayCoordinator)
        .background(
            AppOverlayWindowPresenter(
                coordinator: overlayCoordinator,
                haptics: haptics,
                modelContainer: eventDetailPreviewContainer
            )
        )
    }

    private var previewHomeContent: some View {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
    }

    private var sheetContainer: some View {
        VStack(spacing: 0) {
            EventDetailView(
                event: event,
                onClose: {},
                onRequestSymbolPicker: presentSymbolPicker(_:),
                onRequestTagList: presentTagList(_:)
            )
            .transition(.opacity)
        }
        .presentationDetents([.large], selection: $selectedSheetDetent)
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
        .presentationBackgroundInteraction(.enabled)
        .interactiveDismissDisabled()
        .padding(15)
    }

    private func presentSymbolPicker(_ presentation: SymbolPickerPresentation) {
        overlayCoordinator.present(
            .symbolPicker(
                presentation: presentation,
                onDismiss: {}
            )
        )
    }

    private func presentTagList(_ presentation: TagListPresentation) {
        overlayCoordinator.present(
            .tagList(
                presentation: presentation,
                onDismiss: {}
            )
        )
    }
}

let eventDetailPreviewContainer: ModelContainer = {
    let container = ModelContainerProvider.makePreviewContainer()
    let context = container.mainContext

    let notebooks = [
        Notebook(name: "家庭", colorHex: "FF8A65", iconSystemName: "house.fill"),
        Notebook(name: "工作", colorHex: "5C6BC0", iconSystemName: "briefcase.fill"),
        Notebook(name: "旅行", colorHex: "26A69A", iconSystemName: "airplane"),
        Notebook(name: "学习", colorHex: "7E57C2", iconSystemName: "book.fill")
    ]

    let tags = [
        Tag(name: "健康"),
        Tag(name: "暑假计划")
    ]

    notebooks.forEach(context.insert)
    tags.forEach(context.insert)

    let event = Event(
        title: "Project Launch",
        note: "这一块先放一段预览备注，方便继续调 noteSection。",
        targetDate: Calendar.current.date(byAdding: .day, value: 12, to: .now) ?? .now,
        allDay: true,
        iconSystemName: "flag.fill",
        notebook: notebooks[1],
        tags: tags
    )

    context.insert(event)

    [
        ChecklistItem(title: "还没做好的事情", isCompleted: false, sortIndex: 3),
        ChecklistItem(title: "还没做好的事情", isCompleted: true, sortIndex: 2),
        ChecklistItem(title: "空标题后再退格会删除", isCompleted: false, sortIndex: 1)
    ].forEach { item in
        context.insert(item)
        event.checklistItems.append(item)
    }

    return container
}()

let eventDetailPreviewEvent: Event = {
    let context = eventDetailPreviewContainer.mainContext
    let descriptor = FetchDescriptor<Event>()
    return (try? context.fetch(descriptor).first) ?? Event(title: "Preview Event", targetDate: .now)
}()
