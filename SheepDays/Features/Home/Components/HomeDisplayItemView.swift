//
//  HomeDisplayItemView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/2.
//

import SwiftUI

enum HomeItemBadgeDisplayMode {
    case relativeText
    case date
}

struct HomeDisplayItemView: View {
    let item: HomeDisplayItem
    var badgeDisplayMode: HomeItemBadgeDisplayMode = .relativeText
    var badgeDate: Date?

    private var iconColor: Color {
        if let tintHex = item.tintHex,
           let color = Color(hex: tintHex) {
            return color
        }

        return .accentColor
    }

    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            Image(systemName: item.iconSystemName ?? "figure.roll.runningpace")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .frame(width: 20)
                .foregroundStyle(iconColor)

            Text(item.title)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            badgeView
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
//        .background(
//            RoundedRectangle(cornerRadius: 20, style: .continuous)
//                .fill(Color(.secondarySystemBackground))
//        )
    }
}

private extension HomeDisplayItemView {
    @ViewBuilder
    var badgeView: some View {
        switch badgeDisplayMode {
        case .relativeText:
            if let badgeText = item.badgeText {
                Text(badgeText)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        item.isToday ? iconColor : Color(.secondaryLabel)
                    )
                    .contentTransition(.numericText())
            }
        case .date:
            if let badgeDate {
                SDDateBadge(date: badgeDate)
            } else if let badgeText = item.badgeText {
                Text(badgeText)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        item.isToday ? iconColor : Color(.secondaryLabel)
                    )
                    .contentTransition(.numericText())
            }
        }
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
                tintHex: "#FF7A7A",
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
                tintHex: "#7EC8E3",
                badgeText: "Today",
                isToday: true,
                sortKey: 0,
                groupKey: nil
            )
        )

        HomeDisplayItemView(
            item: HomeDisplayItem(
                id: UUID(),
                sourceEventId: UUID(),
                title: "Trip",
                iconSystemName: "airplane",
                tintHex: "#7EC8E3",
                badgeText: "+14",
                isToday: false,
                sortKey: 0,
                groupKey: nil
            ),
            badgeDisplayMode: .date,
            badgeDate: Calendar.current.date(byAdding: .day, value: 14, to: .now) ?? .now
        )

        HomeDisplayItemView(
            item: HomeDisplayItem(
                id: UUID(),
                sourceEventId: UUID(),
                title: "Trip",
                iconSystemName: "airplane",
                tintHex: "#7EC8E3",
                badgeText: "+14",
                isToday: false,
                sortKey: 0,
                groupKey: nil
            ),
            badgeDisplayMode: .date,
            badgeDate: Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now
        )
    }
    .padding()
}
