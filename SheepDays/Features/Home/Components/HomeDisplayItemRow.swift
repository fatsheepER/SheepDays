//
//  HomeDisplayItemRow.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/21.
//

import SwiftUI

struct HomeDisplayItemRow: View {
    @Environment(\.haptics) private var haptics

    let item: HomeDisplayItem
    var badgeDisplayMode: HomeItemBadgeDisplayMode = .relativeText
    var badgeDate: Date?
    var openDetail: () -> Void = {}
    var jumpToEventDate: () -> Void = {}

    var body: some View {
        let primaryAction: () -> Void = {
            openDetailWithFeedback()
        }
        let badgeAction: (() -> Void)? = canJumpToEventDate ? {
            jumpToEventDateWithFeedback()
        } : nil

        return HomeDisplayItemView(
            item: item,
            badgeDisplayMode: badgeDisplayMode,
            badgeDate: badgeDate,
            primaryAction: primaryAction,
            badgeAction: badgeAction
        )
        .contextMenu(menuItems: {
            Button(action: openDetailWithoutFeedback) {
                Label("查看详情", systemImage: "info.circle")
            }

            Button(action: jumpToEventDateWithoutFeedback) {
                Label("跳到该日期", systemImage: "calendar")
            }
            .disabled(!canJumpToEventDate)
        })
    }
}

private extension HomeDisplayItemRow {
    var canJumpToEventDate: Bool {
        badgeDate != nil
    }

    func openDetailWithFeedback() {
        haptics.play(.openDetailTap)
        openDetail()
    }

    func openDetailWithoutFeedback() {
        openDetail()
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
}

#Preview {
    VStack {
        HomeDisplayItemRow(
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
            ),
            badgeDate: Calendar.current.date(byAdding: .day, value: 3, to: .now)
        )

        HomeDisplayItemRow(
            item: HomeDisplayItem(
                id: UUID(),
                sourceEventId: UUID(),
                title: "Trip",
                iconSystemName: "airplane",
                tintHex: "#7EC8E3",
                badgeText: "Today",
                isToday: true,
                sortKey: 0,
                groupKey: nil
            ),
            badgeDate: .now
        )
    }
    .padding()
}
