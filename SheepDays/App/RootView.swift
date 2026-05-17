//
//  ContentView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.haptics) private var haptics
    @StateObject private var overlayCoordinator = AppOverlayCoordinator()

    var body: some View {
        HomeView()
            .environment(\.appOverlayCoordinator, overlayCoordinator)
            .background(
                AppOverlayWindowPresenter(
                    coordinator: overlayCoordinator,
                    haptics: haptics
                )
            )
    }
}

#Preview {
    RootView()
        .modelContainer(ModelContainerProvider.makePreviewContainer())
}
