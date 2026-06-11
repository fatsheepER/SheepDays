//
//  SDElasticPopoverMenu.swift
//  SheepDays
//
//  Created by Codex on 2026/6/11.
//

import SwiftUI

struct SDElasticPopoverMenu<Label: View, Content: View>: View {
    private let transitionID: String
    private let onToggle: () -> Void
    private let label: () -> Label
    private let content: () -> Content

    @State private var isExpanded = false
    @Namespace private var namespace

    init(
        transitionID: String = "SDElasticPopoverMenu",
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder content: @escaping () -> Content,
        onToggle: @escaping () -> Void = {}
    ) {
        self.transitionID = transitionID
        self.onToggle = onToggle
        self.label = label
        self.content = content
    }

    init(
        transitionID: String = "SDElasticPopoverMenu",
        onToggle: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            transitionID: transitionID,
            label: label,
            content: content,
            onToggle: onToggle
        )
    }

    var body: some View {
        Button {
            onToggle()
            isExpanded.toggle()
        } label: {
            label()
        }
        .buttonBorderShape(.capsule)
        .buttonStyle(.glass)
        .matchedTransitionSource(id: transitionID, in: namespace)
        .popover(isPresented: $isExpanded) {
            SDElasticPopoverContentReveal {
                content()
            }
            .presentationCompactAdaptation(.popover)
            .navigationTransition(.zoom(sourceID: transitionID, in: namespace))
        }
    }
}

private struct SDElasticPopoverContentReveal<Content: View>: View {
    private let content: () -> Content

    @State private var isVisible = false

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .opacity(isVisible ? 1 : 0)
            .task {
                try? await Task.sleep(for: .milliseconds(100))

                guard !Task.isCancelled else {
                    return
                }

                withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                    isVisible = true
                }
            }
    }
}

#Preview {
    SDElasticPopoverMenu {
        Label("More", systemImage: "ellipsis")
            .padding(.horizontal, 10)
    } content: {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popover")
                .font(.headline)
            Text("Reusable elastic popover content.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 260)
    }
    .padding()
}
