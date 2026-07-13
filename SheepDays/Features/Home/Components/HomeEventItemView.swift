//
//  HomeEventItemView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/21.
//

import SwiftUI

struct HomeEventItemView: View {
    @Environment(\.haptics) private var haptics

    let item: HomeDisplayItem
    var badgeDisplayMode: SDEventItemBadgeDisplayMode = .relativeText
    var badgeDate: Date?
    var visibleStateIndicators: Set<HomeDisplayItemStateIndicator> = .home
    var openDetail: () -> Void = {}
    var jumpToEventDate: () -> Void = {}
    var setRelativeValue: (() -> Void)?

    var body: some View {
        let primaryAction: () -> Void = {
            openDetail()
        }
        let badgeAction: (() -> Void)? = canJumpToEventDate ? {
            jumpToEventDateWithFeedback()
        } : nil

        return SDEventItemView(
            item: item,
            badgeDisplayMode: badgeDisplayMode,
            badgeDate: badgeDate,
            visibleStateIndicators: visibleStateIndicators,
            primaryAction: primaryAction,
            badgeAction: badgeAction
        )
        .contextMenu(menuItems: {
            Button(action: openDetail) {
                Label("查看详情", systemImage: "info.circle")
            }

            Button(action: jumpToEventDateWithoutFeedback) {
                Label("跳到该日期", systemImage: "calendar")
            }
            .disabled(!canJumpToEventDate)

            Button(action: setRelativeValueWithoutFeedback) {
                Label("设置相对数值", systemImage: "number")
            }
            .disabled(!canSetRelativeValue)
        })
    }
}

private extension HomeEventItemView {
    var canJumpToEventDate: Bool {
        badgeDate != nil
    }

    var canSetRelativeValue: Bool {
        badgeDate != nil && setRelativeValue != nil
    }

    func jumpToEventDateWithFeedback() {
        guard canJumpToEventDate else {
            return
        }

        haptics.play(.jumpToDateDoubleTap)
        jumpToEventDate()
    }

    func jumpToEventDateWithoutFeedback() {
        guard canJumpToEventDate else {
            return
        }

        jumpToEventDate()
    }

    func setRelativeValueWithoutFeedback() {
        guard canSetRelativeValue else {
            return
        }

        setRelativeValue?()
    }
}

#Preview {
    VStack {
        HomeEventItemView(
            item: HomeDisplayItem(
                id: UUID(),
                sourceEventId: UUID(),
                title: "Project Launch",
                iconSystemName: "flag.fill",
                tintHex: "#FF7A7A",
                badgeText: "+3",
                isToday: false,
                stateIndicators: [.checklist, .showOnHome],
                sortKey: 0,
                groupKey: nil
            ),
            badgeDate: Calendar.current.date(byAdding: .day, value: 3, to: .now)
        )

        HomeEventItemView(
            item: HomeDisplayItem(
                id: UUID(),
                sourceEventId: UUID(),
                title: "Trip",
                iconSystemName: "airplane",
                tintHex: "#7EC8E3",
                badgeText: "Today",
                isToday: true,
                stateIndicators: [.checklist, .reminder, .showOnHome],
                sortKey: 0,
                groupKey: nil
            ),
            badgeDate: .now,
            visibleStateIndicators: .notebookDetail
        )
    }
    .padding()
}
