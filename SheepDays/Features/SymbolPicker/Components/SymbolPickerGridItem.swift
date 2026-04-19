//
//  SymbolPickerGridItem.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/18.
//

import SwiftUI

struct SymbolPickerGridItem: View {
    let choice: SFSymbolChoice
    let isSelected: Bool
    let tintColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack() {
                Image(systemName: choice.systemName)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .frame(width: 28, height: 28)
                    .foregroundStyle(isSelected ? tintColor : .secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .padding(.horizontal, 4)
            .overlay(selectionOutline)
        }
        .buttonStyle(.plain)
    }
    @ViewBuilder
    private var selectionOutline: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(isSelected ? tintColor.opacity(0.15) : Color(.separator).opacity(0), lineWidth: 2)
    }
}

#Preview {
    SymbolPickerGridItem(
        choice: SFSymbolChoice(systemName: "star.fill", title: "星标"),
        isSelected: true,
        tintColor: .orange
    ) {}
    .padding()
    .background(Color(.systemGroupedBackground))
}
