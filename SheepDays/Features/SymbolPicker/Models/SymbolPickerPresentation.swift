//
//  SymbolPickerPresentation.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/18.
//

import SwiftUI

struct SymbolPickerPresentation: Identifiable {
    static let defaultRecentSymbolLimit = 8

    let id = UUID()
    let title: String
    let sections: [SFSymbolSection]
    let selectedSystemName: String?
    let tintColor: Color
    let recentSymbolLimit: Int
    let onSelect: (String?) -> Void

    init(
        title: String,
        sections: [SFSymbolSection],
        selectedSystemName: String?,
        tintColor: Color,
        recentSymbolLimit: Int = Self.defaultRecentSymbolLimit,
        onSelect: @escaping (String?) -> Void
    ) {
        self.title = title
        self.sections = sections
        self.selectedSystemName = selectedSystemName
        self.tintColor = tintColor
        self.recentSymbolLimit = recentSymbolLimit
        self.onSelect = onSelect
    }
}
