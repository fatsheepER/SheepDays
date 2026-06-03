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
    var visibleStateIndicators: Set<HomeDisplayItemStateIndicator> = .home
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
        HStack {
            primaryContent

            Spacer()

            stateIndicatorsView
                .transition(.opacity.combined(with: .blurReplace))
            
            badgeView
                .transition(.move(edge: .bottom).combined(with: .blurReplace))
        }
        .padding(.vertical, 12.5)
    }
}

private extension HomeDisplayItemView {
    var displayedStateIndicators: [HomeDisplayItemStateIndicator] {
        HomeDisplayItemStateIndicator.allCases.filter {
            item.stateIndicators.contains($0) && visibleStateIndicators.contains($0)
        }
    }

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
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: item.iconSystemName ?? "figure.roll.runningpace")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .frame(width: 40, height: 30)
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)

            Text(item.title)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(item.isToday ? iconColor : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    var stateIndicatorsView: some View {
        if !displayedStateIndicators.isEmpty {
            HStack(spacing: 5) {
                ForEach(displayedStateIndicators) { indicator in
                    stateIndicatorIcon(indicator)
                }
            }
            .accessibilityElement(children: .contain)
        }
    }

    func stateIndicatorIcon(_ indicator: HomeDisplayItemStateIndicator) -> some View {
        Image(systemName: indicator.systemName)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(.tertiaryLabel))
            .frame(width: 20)
            .accessibilityLabel(Text(indicator.accessibilityLabel))
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
            .frame(minHeight: 30)
            .background(
                Capsule()
                    .fill(item.isToday ? iconColor.opacity(0.2) : Color(.tertiarySystemFill))
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
    VStack(spacing: 5) {
        HomeDisplayItemView(
            item: HomeDisplayItem(
                id: UUID(),
                sourceEventId: UUID(),
                title: "Project Launch",
                iconSystemName: "flag.fill",
                tintHex: "#FF7A7A",
                badgeText: "+3",
                isToday: false,
                stateIndicators: [.checklist, .showOnHome, .pinned],
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
                stateIndicators: [.checklist, .reminder, .showOnHome],
                sortKey: 0,
                groupKey: nil
            ),
            visibleStateIndicators: .notebookDetail
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
