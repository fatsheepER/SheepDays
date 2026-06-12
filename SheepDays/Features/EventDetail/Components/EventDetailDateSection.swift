//
//  EventDetailDateSection.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/6/12.
//

import SwiftUI

struct EventDetailDateSection: View {
    @Binding var date: Date
    let range: ClosedRange<Date>

    var body: some View {
        HStack {
            EventDetailSectionTitle(title: "日期", systemImage: "calendar")

            Spacer()

            SDDatePicker(date: $date, range: range)
        }
    }
}

#Preview {
    @Previewable @State var date = Date()

    EventDetailDateSection(
        date: $date,
        range: Date.distantPast...Date.distantFuture
    )
    .padding()
}
