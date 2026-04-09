//
//  NotebookEditorOverlayView.swift
//  SheepDays
//
//  Created by Codex on 2026/4/9.
//

import SwiftUI
import SwiftData

struct NotebookEditorOverlayView: View {
    let notebook: Notebook?
    var onClose: () -> Void = {}
    var onNotebookUpdated: () -> Void = {}

    var body: some View {
        ZStack(alignment: .bottom) {
            if notebook != nil {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onClose)
                    .transition(.opacity)
            }

            if let notebook {
                NotebookEditorView(
                    notebook: notebook,
                    onClose: onClose,
                    onNotebookUpdated: onNotebookUpdated
                )
                .padding(.horizontal, 15)
                .padding(.vertical, 15)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(notebook != nil)
    }
}

#Preview {
    NotebookEditorOverlayView(
        notebook: Notebook(
            name: "生活",
            colorHex: "FF8A65",
            iconSystemName: "leaf.fill"
        )
    )
    .modelContainer(ModelContainerProvider.makePreviewContainer())
}
