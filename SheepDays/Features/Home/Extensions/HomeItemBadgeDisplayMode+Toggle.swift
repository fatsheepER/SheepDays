//
//  HomeItemBadgeDisplayMode+Toggle.swift
//  SheepDays
//
//  Created by Codex on 2026/6/12.
//

extension HomeItemBadgeDisplayMode {
    mutating func toggle() {
        switch self {
        case .relativeText:
            self = .date
        case .date:
            self = .relativeText
        }
    }
}
