//
//  SymbolPickerChoice.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/18.
//

import Foundation

struct SFSymbolChoice: Identifiable, Hashable {
    let id: String
    let systemName: String
    let title: String

    init(systemName: String, title: String) {
        self.id = systemName
        self.systemName = systemName
        self.title = title
    }
}
