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
    var primaryAction: (() -> Void)?
    var badgeAction: (() -> Void)?

    private var iconColor: Color {
        if let tintHex = item.tintHex,
           let color = Color(hex: tintHex) {
            return color
        }

        return .accentColor
    }

    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            primaryContent

            badgeView
                .transition(.move(edge: .bottom).combined(with: .opacity))
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
    var primaryContent: some View {
        if let primaryAction {
            Button(action: primaryAction) {
                primaryContentLabel
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.title)
            .accessibilityHint("查看详情")
        } else {
            primaryContentLabel
        }
    }

    var primaryContentLabel: some View {
        HStack(alignment: .center, spacing: 15) {
            Image(systemName: item.iconSystemName ?? "figure.roll.runningpace")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .frame(width: 20)
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)

            Text(item.title)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(item.isToday ? iconColor : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    var badgeView: some View {
        switch badgeDisplayMode {
        case .relativeText:
            if let badgeText = item.badgeText {
                badgeContainer {
                    textBadge(text: badgeText)
                }
            }
        case .date:
            if let badgeDate {
                badgeContainer {
                    SDDateBadge(date: badgeDate)
                }
            } else if let badgeText = item.badgeText {
                badgeContainer {
                    textBadge(text: badgeText)
                }
            }
        }
    }

    @ViewBuilder
    func badgeContainer<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        if let badgeAction, let badgeDate {
            Button(action: badgeAction) {
                content()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("跳到该日期")
            .accessibilityValue(Text(accessibilityDateLabel(for: badgeDate)))
            .accessibilityHint("跳转到这个事件的发生日期")
        } else {
            content()
        }
    }

    func textBadge(text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(
                item.isToday ? iconColor : Color(.secondaryLabel)
            )
            .contentTransition(.numericText())
            .padding(.horizontal, 10)
            .frame(minHeight: 31)
            .background(
                Capsule()
                    .fill(Color(.secondarySystemBackground))
            )
    }

    func accessibilityDateLabel(for date: Date) -> String {
        date.formatted(
            .dateTime
                .year()
                .month()
                .day()
                .locale(.autoupdatingCurrent)
        )
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
