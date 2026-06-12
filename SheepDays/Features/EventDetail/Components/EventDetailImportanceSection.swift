//
//  EventDetailImportanceSection.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/6/12.
//

import SwiftUI

struct EventDetailImportanceSection: View {
    let importanceLevel: Int
    let levelText: String
    let accentColor: Color
    let onSetLevel: (Int) -> Void

    var body: some View {
        VStack {
            HStack {
                EventDetailSectionTitle(title: "重要性", systemImage: "flag")

                Spacer()

                Text(levelText)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(.tertiaryLabel))
            }

            HStack {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        onSetLevel(level)
                    } label: {
                        Capsule()
                            .frame(height: 10)
                            .foregroundStyle(
                                importanceLevel >= level
                                ? accentColor
                                : Color(.tertiarySystemFill)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical)
            .padding(.horizontal)
        }
    }
}

#Preview {
    @Previewable @State var importanceLevel = 3

    EventDetailImportanceSection(
        importanceLevel: importanceLevel,
        levelText: "\(importanceLevel)/5",
        accentColor: .orange,
        onSetLevel: { importanceLevel = $0 }
    )
    .padding()
}
