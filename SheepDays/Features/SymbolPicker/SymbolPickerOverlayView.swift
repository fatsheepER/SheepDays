//
//  SymbolPickerOverlayView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/18.
//

import SwiftUI

struct SymbolPickerOverlayView: View {
    let isPresented: Bool
    let title: String
    let sections: [SFSymbolSection]
    let selectedSystemName: String?
    let tintColor: Color
    let onSelect: (String?) -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .center) {
            if isPresented {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onClose)
                    .transition(.opacity)
            }

            if isPresented {
                SymbolPickerView(
                    title: title,
                    sections: sections,
                    selectedSystemName: selectedSystemName,
                    tintColor: tintColor,
                    onSelect: onSelect,
                    onClose: onClose
                )
                .padding(.horizontal, 25)
                .padding(.vertical, 50)
                .frame(maxHeight: 700)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(isPresented)
    }
}

#Preview {
    ZStack {
        Color(.secondarySystemBackground)
            .ignoresSafeArea()

        SymbolPickerOverlayView(
            isPresented: true,
            title: "选择事件本图标",
            sections: SFSymbolLibrary.notebookSections,
            selectedSystemName: "book.closed.fill",
            tintColor: .orange,
            onSelect: { _ in },
            onClose: {}
        )
    }
}
