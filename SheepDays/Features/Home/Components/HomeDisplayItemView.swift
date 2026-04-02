//
//  HomeDisplayItemView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/2.
//

import SwiftUI

struct HomeDisplayItemView: View {
    let item: HomeDisplayItem

    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            
            Image(systemName: item.iconSystemName ?? "figure.roll.runningpace")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .frame(width: 20)
                .foregroundStyle(.accent)

            Text(item.title)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let badgeText = item.badgeText {
//                SDBadge(text: badgeText)
                
                Text(badgeText)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        item.isToday ? Color(.accent) : Color(.secondaryLabel)
                    )
                    .contentTransition(.numericText())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
//        .background(
//            RoundedRectangle(cornerRadius: 20, style: .continuous)
//                .fill(Color(.secondarySystemBackground))
//        )
    }
}

#Preview {
    VStack {
        HomeDisplayItemView(
            item: HomeDisplayItem(
                id: UUID(),
                sourceEventId: UUID(),
                title: "Project Launch",
                iconSystemName: "flag.fill",
                badgeText: "+3",
                isToday: false,
                sortKey: 0,
                groupKey: nil
            )
        )
        
        HomeDisplayItemView(
            item: HomeDisplayItem(
                id: UUID(),
                sourceEventId: UUID(),
                title: "Project Launch",
                iconSystemName: "flag.fill",
                badgeText: "Today",
                isToday: true,
                sortKey: 0,
                groupKey: nil
            )
        )
    }
    .padding()
}
