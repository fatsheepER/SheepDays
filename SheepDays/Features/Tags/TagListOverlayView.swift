//
//  TagListOverlayView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/5/15.
//

import SwiftUI
import SwiftData

struct TagListOverlayView: View {
    let isPresented: Bool
    let mode: TagListMode
    let presentationDelay: Duration
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
                TagListView(mode: mode, onClose: requestClose)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 50)
                    .frame(maxHeight: 600)
                    .transition(.move(edge: .bottom).combined(with: .blurReplace))
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

private extension TagListOverlayView {
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

        TagListOverlayView(
            isPresented: true,
            mode: .management,
            presentationDelay: .zero,
            onClose: {}
        )
    }
    .modelContainer(tagListOverlayPreviewContainer)
}

private let tagListOverlayPreviewContainer: ModelContainer = {
    let container = ModelContainerProvider.makePreviewContainer()
    let context = container.mainContext

    [
        Tag(name: "暑假计划"),
        Tag(name: "新技能"),
        Tag(name: "健康")
    ].forEach(context.insert)

    return container
}()
