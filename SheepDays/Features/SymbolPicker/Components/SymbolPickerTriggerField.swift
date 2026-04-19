//
//  SymbolPickerTriggerField.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/18.
//

import SwiftUI

struct SymbolPickerTriggerField: View {
    let label: String
    let systemName: String?
    let tintColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemName ?? "questionmark.circle")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(tintColor)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(tintColor.opacity(0.14))
                    )

                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SymbolPickerTriggerField(
        label: "选择图标",
        systemName: "calendar.badge.clock",
        tintColor: .orange
    ) {}
    .padding()
    .background(Color(.systemGroupedBackground))
}
