//
//  SDTagBadge.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/2.
//

import SwiftUI

struct SDTagBadge: View {
    let tag: Tag?

    private var title: String {
        tag?.name ?? "无标签"
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Image(systemName: "number")
            Text(title)
        }
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(Color(.secondaryLabel))
        .padding(10)
        .background(
            Capsule()
                .foregroundStyle(Color(.quaternarySystemFill))
        )
        .frame(height: 35)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        SDTagBadge(tag: Tag(name: "健康"))
        SDTagBadge(tag: nil)
    }
    .padding()
}
