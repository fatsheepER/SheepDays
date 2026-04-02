//
//  Untitled.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import Foundation

struct HomeDisplayItem: Identifiable {
    let id: UUID
    let sourceEventId: UUID

    let title: String
    let iconSystemName: String?
    let badgeText: String?
    let isToday: Bool

    let sortKey: Double
    let groupKey: String?
}
