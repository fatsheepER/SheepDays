//
//  SDDateBadge.swift
//  SheepDays
//
//  Created by Codex on 2026/4/2.
//

import SwiftUI

struct SDDateBadge: View {
    let date: Date

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "calendar")
                .accessibilityHidden(true)
            Text(dateLabel)
                .contentTransition(.numericText())
        }
        .font(.system(size: 15, weight: .semibold, design: .rounded))
        .foregroundStyle(Color(.secondaryLabel))
        .padding(.horizontal, 10)
        .frame(minHeight: 31)
        .background(
            Capsule()
                .fill(Color(.secondarySystemBackground))
        )
    }
}

private extension SDDateBadge {
    var dateLabel: String {
        let calendar = Calendar.autoupdatingCurrent
        let isCurrentYear = calendar.isDate(date, equalTo: .now, toGranularity: .year)

        if isCurrentYear {
            return date.formatted(
                .dateTime
                    .month(.defaultDigits)
                    .day()
                    .locale(.autoupdatingCurrent)
            )
        }

        return date.formatted(
            .dateTime
                .year()
                .month(.defaultDigits)
                .day()
                .locale(.autoupdatingCurrent)
        )
    }
}

#Preview {
    SDDateBadge(date: .now)
        .padding()
}
