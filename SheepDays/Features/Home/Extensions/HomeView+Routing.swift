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
            selectedNotebook = nil
            notebookEditorOption = nil
            sheetRoute = .home
        }
    }

    func showFocus() {
        haptics.play(.openDetailTap)
        selectedEvent = nil
        selectedNotebook = nil
        notebookEditorOption = nil
        sheetRoute = .focus
    }

    func showQuickAdd() {
        haptics.play(.openDetailTap)
        withAnimation(.spring(duration: 0.2)) {
            shouldFocusQuickAddTitle = true
            selectedEvent = nil
            selectedNotebook = nil
            notebookEditorOption = nil
            sheetRoute = .quickAdd
        }
    }

    func showNotebooks() {
        haptics.play(.openDetailTap)
        withAnimation {
            selectedEvent = nil
            selectedNotebook = nil
            notebookEditorOption = nil
            sheetRoute = .notebooks
        }
    }

    func showSettings() {
        selectedEvent = nil
        selectedNotebook = nil
        notebookEditorOption = nil
        sheetRoute = .settings
    }

    func showNotebookCreator() {
        haptics.play(.openDetailTap)
        withAnimation(.spring(duration: 0.2)) {
            notebookEditorOption = .create
            selectedEvent = nil
            selectedNotebook = nil
            sheetRoute = .notebookEditor
        }
    }

    func showNotebookEditor(for notebook: Notebook) {
        haptics.play(.openDetailTap)
        withAnimation(.spring(duration: 0.2)) {
            notebookEditorOption = .edit(notebook)
            selectedEvent = nil
            selectedNotebook = nil
            sheetRoute = .notebookEditor
        }
    }

    func showNotebookDetail(for notebook: Notebook) {
        haptics.play(.openDetailTap)
        withAnimation(.spring(duration: 0.2)) {
            selectedNotebook = notebook
            selectedEvent = nil
            notebookEditorOption = nil
            sheetRoute = .notebookDetail
        }
    }
}
