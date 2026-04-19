//
//  SFSymbolSection.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/18.
//

import Foundation

struct SFSymbolSection: Identifiable, Hashable {
    let id: String
    let title: String
    let symbols: [SFSymbolChoice]

    init(title: String, symbols: [SFSymbolChoice]) {
        self.id = title.lowercased().replacingOccurrences(of: " ", with: "-")
        self.title = title
        self.symbols = symbols
    }
}
