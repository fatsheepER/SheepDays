//
//  NotebookEditorOverlayView.swift
//  SheepDays
//
//  Created by Codex on 2026/4/9.
//

import SwiftUI
import SwiftData

struct NotebookEditorOverlayView: View {
    let option: NotebookEditorOption?
    var onClose: () -> Void = {}
    var onNotebookUpdated: () -> Void = {}

    var body: some View {
        ZStack(alignment: .bottom) {
            if option != nil {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onClose)
                    .transition(.opacity)
            }

            if let option {
                NotebookEditorView(
                    option: option,
                    onClose: onClose,
                    onNotebookUpdated: onNotebookUpdated
                )
                .padding(.horizontal, 15)
                .padding(.vertical, 15)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(option != nil)
    }
}

#Preview {
    NotebookEditorOverlayView(
        option: .create
    )
    .modelContainer(ModelContainerProvider.makePreviewContainer())
}
