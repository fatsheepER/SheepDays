//
//  EventDetailOverlayView.swift
//  SheepDays
//
//  Created by Codex on 2026/4/2.
//

import SwiftUI

struct EventDetailOverlayView: View {
    let event: Event
    var onClose: () -> Void = {}

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            EventDetailView(event: event, onClose: onClose)
                .frame(maxWidth: 700, maxHeight: 700)
                .padding(.horizontal, 25)
                .transition(.scale(scale: 0.96).combined(with: .opacity))
        }
    }
}

#Preview {
    EventDetailOverlayView(
        event: Event(
            title: "Project Launch",
            targetDate: .now,
            allDay: true,
            notebook: Notebook(name: "Work", colorHex: "5C6BC0", iconSystemName: "briefcase.fill")
        )
    )
    .modelContainer(ModelContainerProvider.makePreviewContainer())
}
