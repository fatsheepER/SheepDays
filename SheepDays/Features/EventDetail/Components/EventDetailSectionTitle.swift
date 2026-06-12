//
//  EventDetailSectionTitle.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/6/12.
//

import SwiftUI

struct EventDetailSectionTitle: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .medium))

            Text(title)
                .font(.system(size: 18, weight: .semibold))
        }
        .frame(height: 35)
        .foregroundStyle(Color(.secondaryLabel))
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        EventDetailSectionTitle(title: "备注", systemImage: "note.text")
        EventDetailSectionTitle(title: "日期", systemImage: "calendar")
        EventDetailSectionTitle(title: "检查清单", systemImage: "checklist")
    }
    .padding()
}
