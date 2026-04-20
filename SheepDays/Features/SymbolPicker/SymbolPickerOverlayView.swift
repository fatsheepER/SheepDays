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
    let presentationDelay: Duration
    let onSelect: (String?) -> Void
    let onClose: () -> Void

    @State private var isBackdropVisible = false
    @State private var isCardVisible = false
    @State private var isAnimatingDismissal = false
    @State private var presentationTask: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .center) {
            if isBackdropVisible {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture(perform: requestClose)
                    .transition(.opacity)
            }

            if isCardVisible {
                SymbolPickerView(
                    title: title,
                    sections: sections,
                    selectedSystemName: selectedSystemName,
                    tintColor: tintColor,
                    onSelect: onSelect,
                    onClose: requestClose
                )
                .padding(.horizontal, 25)
                .padding(.vertical, 50)
                .frame(maxHeight: 700)
                .transition(.move(edge: .bottom))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(isBackdropVisible || isCardVisible)
        .onAppear {
            if isPresented {
                schedulePresentation()
            }
        }
        .onChange(of: isPresented) { _, newValue in
            if newValue {
                schedulePresentation()
            } else {
                hideImmediately()
            }
        }
        .onDisappear {
            presentationTask?.cancel()
        }
    }
}

private extension SymbolPickerOverlayView {
    func schedulePresentation() {
        presentationTask?.cancel()

        guard !isBackdropVisible || !isCardVisible else {
            return
        }

        if presentationDelay == .zero {
            presentAnimated()
            return
        }

        presentationTask = Task { @MainActor in
            try? await Task.sleep(for: presentationDelay)

            guard !Task.isCancelled else {
                return
            }

            presentAnimated()
        }
    }

    func presentAnimated() {
        guard !isBackdropVisible || !isCardVisible else {
            return
        }

        isAnimatingDismissal = false

        withAnimation(.easeOut(duration: 0.18)) {
            isBackdropVisible = true
        }

        withAnimation(.snappy(duration: 0.32, extraBounce: 0)) {
            isCardVisible = true
        }
    }

    func requestClose() {
        guard !isAnimatingDismissal else {
            return
        }

        presentationTask?.cancel()
        isAnimatingDismissal = true

        withAnimation(.easeIn(duration: 0.18)) {
            isBackdropVisible = false
        }

        withAnimation(.snappy(duration: 0.24, extraBounce: 0)) {
            isCardVisible = false
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(240))
            onClose()
        }
    }

    func hideImmediately() {
        presentationTask?.cancel()
        isAnimatingDismissal = false
        isBackdropVisible = false
        isCardVisible = false
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
            presentationDelay: .zero,
            onSelect: { _ in },
            onClose: {}
        )
    }
}
