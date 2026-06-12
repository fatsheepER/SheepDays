//
//  EventDetailToggleRow.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/6/12.
//

import SwiftUI

struct EventDetailToggleRow: View {
    let title: String
    let systemImage: String
    @Binding var isOn: Bool
    let accentColor: Color

    var body: some View {
        HStack {
            EventDetailSectionTitle(title: title, systemImage: systemImage)

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(accentColor)
        }
    }
}

#Preview {
    @Previewable @State var isOn = true

    VStack(spacing: 15) {
        EventDetailToggleRow(
            title: "显示在首页",
            systemImage: "star",
            isOn: $isOn,
            accentColor: .orange
        )

        EventDetailToggleRow(
            title: "纪念日",
            systemImage: "calendar.badge.clock",
            isOn: .constant(false),
            accentColor: .orange
        )
    }
    .padding()
}
