//
//  EventDetailOverlayView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/6.
//

import SwiftUI
import SwiftData

struct EventDetailOverlayView: View {
    let event: Event
    var onClose: () -> Void = {}
    var onEventUpdated: () -> Void = {}

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
                .transition(.opacity)

            EventDetailView(event: event, onClose: onClose, onEventUpdated: onEventUpdated)
                .frame(maxHeight: 700)
                .padding(.horizontal, 25)
                .transition(.move(edge: .bottom).combined(with: .opacity))
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
