//
//  SymbolPickerSectionView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/18.
//

import SwiftUI

struct SymbolPickerSectionView: View {
    let section: SFSymbolSection
    let selectedSystemName: String?
    let tintColor: Color
    let onSelect: (String) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 40), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(section.symbols) { symbol in
                    SymbolPickerGridItem(
                        choice: symbol,
                        isSelected: selectedSystemName == symbol.systemName,
                        tintColor: tintColor
                    ) {
                        onSelect(symbol.systemName)
                    }
                }
            }
        }
    }
}
