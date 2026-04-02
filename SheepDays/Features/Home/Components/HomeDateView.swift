//
//  HomeDateView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/2.
//

import SwiftUI

struct HomeDateView: View {
    private let content: HomeDateDisplayContent

    init(referenceDate: Date, today: Date = .now, calendar: Calendar = .current) {
        self.content = HomeDateDisplayContent(
            referenceDate: referenceDate,
            today: today,
            calendar: calendar
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(content.yearText)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.accent)

            HStack(alignment: .center, spacing: 0) {
                Text(content.monthText)
                Text(content.separatorText)
                Text(content.dayText)
                    .padding(.leading, 5)
                if content.dayOffsetFromToday != 0 {
                    SDIncreBadge(text: content.badgeText)
                        .padding(.leading, 5)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            .font(.system(size: 32, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
            .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VStack(spacing: 12) {
        HomeDateView(referenceDate: .now)
        HomeDateView(referenceDate: Calendar.current.date(byAdding: .day, value: 4, to: .now) ?? .now)
        HomeDateView(referenceDate: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now)
    }
    .padding()
}
