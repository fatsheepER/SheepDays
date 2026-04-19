//
//  EventDetailOverlayView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/6.
//

import SwiftUI
import SwiftData

struct EventDetailOverlayView: View {
    let event: Event?
    var onClose: () -> Void = {}
    var onEventUpdated: () -> Void = {}

    var body: some View {
        ZStack(alignment: .center) {
            if event != nil {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onClose)
                    .transition(.opacity)
            }

            if let event {
                EventDetailView(event: event, onClose: onClose, onEventUpdated: onEventUpdated)
                    .frame(maxHeight: 700)
                    .padding(.horizontal, 15)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(event != nil)
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
