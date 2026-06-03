//
//  Untitled.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import Foundation

nonisolated enum HomeDisplayItemStateIndicator: Hashable, CaseIterable, Identifiable {
    case checklist
    case recurrence
    case reminder
    case showOnHome
    case pinned

    var id: Self { self }

    var systemName: String {
        switch self {
        case .checklist:
            "checklist"
        case .recurrence:
            "repeat"
        case .reminder:
            "bell.fill"
        case .showOnHome:
            "star.fill"
        case .pinned:
            "pin.fill"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .checklist:
            "包含检查清单"
        case .recurrence:
            "循环事件"
        case .reminder:
            "已设置提醒"
        case .showOnHome:
            "显示在首页"
        case .pinned:
            "已置顶"
        }
    }
}

extension Set where Element == HomeDisplayItemStateIndicator {
    static let home: Self = [.checklist]
    static let notebookDetail: Self = [.checklist, .recurrence, .reminder, .showOnHome, .pinned]
    static let allStateIndicators: Self = Self(HomeDisplayItemStateIndicator.allCases)
}

nonisolated struct HomeDisplayItem: Identifiable {
    let id: UUID
    let sourceEventId: UUID

    let title: String
    let iconSystemName: String?
    let tintHex: String?
    let badgeText: String?
    let isToday: Bool
    let stateIndicators: Set<HomeDisplayItemStateIndicator>

    let sortKey: Double
    let groupKey: String?

    init(
        id: UUID,
        sourceEventId: UUID,
        title: String,
        iconSystemName: String?,
        tintHex: String?,
        badgeText: String?,
        isToday: Bool,
        stateIndicators: Set<HomeDisplayItemStateIndicator> = [],
        sortKey: Double,
        groupKey: String?
    ) {
        self.id = id
        self.sourceEventId = sourceEventId
        self.title = title
        self.iconSystemName = iconSystemName
        self.tintHex = tintHex
        self.badgeText = badgeText
        self.isToday = isToday
        self.stateIndicators = stateIndicators
        self.sortKey = sortKey
        self.groupKey = groupKey
    }
}
