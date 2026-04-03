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
            Text(dateLabel)
        }
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(Color(.secondaryLabel))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color(.secondarySystemBackground))
        )
    }
}

private extension SDDateBadge {
    var dateLabel: String {
        date.formatted(
            .dateTime
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
