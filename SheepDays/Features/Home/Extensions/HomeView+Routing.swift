//
//  HomeView+Routing.swift
//  SheepDays
//
//  Created by Codex on 2026/6/12.
//

import SwiftUI

extension HomeView {
    func showHomeSheet() {
        // haptics depends on caller
        withAnimation(.spring(duration: 0.2)) {
            shouldFocusQuickAddTitle = false
            selectedEvent = nil
            sheetRoute = .home
        }
    }

    func showFocus() {
        haptics.play(.openDetailTap)
        selectedEvent = nil
        sheetRoute = .focus
    }

    func showQuickAdd() {
        haptics.play(.openDetailTap)
        withAnimation(.spring(duration: 0.2)) {
            shouldFocusQuickAddTitle = true
            selectedEvent = nil
            sheetRoute = .quickAdd
        }
    }

    func showNotebooks() {
        haptics.play(.openDetailTap)
        withAnimation(.spring(duration: 0.2)) {
            selectedEvent = nil
            sheetRoute = .home
            isNotebooksSheetPresented = true
        }
    }

    func dismissNotebooks() {
        haptics.play(.openDetailTap)
        isNotebooksSheetPresented = false
    }

    func showSettings() {
        selectedEvent = nil
        sheetRoute = .settings
    }
}
