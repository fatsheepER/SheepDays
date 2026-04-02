//
//  HomeView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import SwiftUI

struct HomeView: View {
    @State private var referenceDate = Calendar.current.startOfDay(for: .now)

    @State private var isBottomSheetPresented = true
    @State private var sheetRoute: HomeSheetRoute = .home

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
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showSettings()
                        } label: {
                            Image(systemName: "gear")
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showQuickAdd()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.glassProminent)
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
    var homeContent: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            // 这里先换成你的主页内容。
            // 之后你可以直接把 ListEventsView() 放回来。
            VStack(spacing: 16) {
                Spacer()

                Text("Home content placeholder")
                    .font(.headline)

                Text(referenceDate.formatted(date: .abbreviated, time: .omitted))
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
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
                    referenceDate = Calendar.current.startOfDay(for: .now)
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
}
