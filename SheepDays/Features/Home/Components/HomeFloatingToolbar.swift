//
//  HomeFloatingToolbar.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/6/12.
//

import SwiftUI

struct HomeFloatingToolbar: View {
    let onAddPreviewEvents: () -> Void
    let onClearPreviewEvents: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            previewActionsMenu
            settingsToolbarButton
        }
    }
}

private extension HomeFloatingToolbar {
    var previewActionsMenu: some View {
        Menu {
            Section("Testing") {
                Button("Add Preview Events", action: onAddPreviewEvents)
                Button("Clear Preview Events", role: .destructive, action: onClearPreviewEvents)
            }
        } label: {
            floatingToolbarIcon(systemName: "ellipsis")
        }
        .buttonStyle(.glass)
        .accessibilityLabel("Preview actions")
    }

    var settingsToolbarButton: some View {
        Button {
            onOpenSettings()
        } label: {
            floatingToolbarIcon(systemName: "gearshape")
        }
        .buttonStyle(.glass)
        .accessibilityLabel("Settings")
    }

    func floatingToolbarIcon(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 20, weight: .medium, design: .rounded))
            .frame(width: 20, height: 30)
            .foregroundStyle(Color(.secondaryLabel))
    }
}
