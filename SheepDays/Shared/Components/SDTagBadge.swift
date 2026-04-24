//
//  SDTagBadge.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/2.
//

import SwiftUI

struct SDTagBadge: View {
    let tag: Tag?
    let isSelected: Bool

    init(tag: Tag?, isSelected: Bool = false) {
        self.tag = tag
        self.isSelected = isSelected
    }

    private var title: String {
        tag?.name ?? "无标签"
    }

    private var activeEventCount: Int {
        tag?.events.filter { !$0.isArchived }.count ?? 0
    }

    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            Image(systemName: "number")
            Text(title)
            
            Text("\(activeEventCount)")
                .font(.system(size: 10, weight: .regular))
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(Color(.secondaryLabel))
        .padding(10)
        .background(
            Capsule()
                .foregroundStyle(Color(.quaternarySystemFill))
        )
        .overlay {
            Capsule()
                .strokeBorder(
                    Color(.secondaryLabel),
                    lineWidth: isSelected ? 2 : 0
                )
        }
        .frame(height: 35)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        SDTagBadge(tag: Tag(name: "健康"))
        SDTagBadge(tag: Tag(name: "工作"), isSelected: true)
        SDTagBadge(tag: nil)
    }
    .padding()
}
