//
//  RecentSFSymbolStore.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/5/17.
//

import Foundation

struct RecentSFSymbolStore {
    static let shared = RecentSFSymbolStore()

    private let userDefaults: UserDefaults
    private let storageKey = "SymbolPicker.recentSystemNames"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load(limit: Int) -> [String] {
        bounded(userDefaults.stringArray(forKey: storageKey) ?? [], limit: limit)
    }

    func record(_ systemName: String, limit: Int) -> [String] {
        guard limit > 0 else {
            return []
        }

        let updatedSystemNames = [systemName] + load(limit: Int.max).filter { $0 != systemName }
        let recentSystemNames = bounded(updatedSystemNames, limit: limit)
        userDefaults.set(recentSystemNames, forKey: storageKey)
        return recentSystemNames
    }

    private func bounded(_ systemNames: [String], limit: Int) -> [String] {
        guard limit > 0 else {
            return []
        }

        return Array(systemNames.prefix(limit))
    }
}
