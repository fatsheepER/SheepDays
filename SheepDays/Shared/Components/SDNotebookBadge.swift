//
//  SDNotebookBadge.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/2.
//

import SwiftUI

struct SDNotebookBadge: View {
    let notebook: Notebook?
    let isSelected: Bool

    init(notebook: Notebook?, isSelected: Bool = true) {
        self.notebook = notebook
        self.isSelected = isSelected
    }

    private var tintColor: Color {
        guard let hex = notebook?.colorHex,
              let color = Color(hex: hex) else {
            return .accentColor
        }

        return color
    }

    private var iconSystemName: String {
        notebook?.iconSystemName ?? "book.closed"
    }

    private var title: String {
        notebook?.name ?? "无事件本"
    }

    private var iconColor: Color {
        isSelected ? .white : tintColor
    }

    private var titleColor: Color {
        isSelected ? .white : Color(.secondaryLabel)
    }

    private var backgroundColor: Color {
        isSelected ? tintColor : Color(.quaternarySystemFill)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Image(systemName: iconSystemName)
                .foregroundStyle(iconColor)

            Text(title)
                .foregroundStyle(titleColor)
        }
        .font(.system(size: 15, weight: .medium))
        .padding(10)
        .background(
            SDRoundedBackground(
                topLeading: 15,
                topTrailing: 15,
                bottomLeading: 15,
                bottomTrailing: 5,
                cornerStyle: .continuous,
                color: backgroundColor
            )
        )
        .frame(height: 35)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        SDNotebookBadge(
            notebook: Notebook(
                name: "家庭",
                colorHex: "FF8A65",
                iconSystemName: "house.fill"
            ),
            isSelected: true
        )

        SDNotebookBadge(
            notebook: Notebook(
                name: "学校",
                colorHex: "1B9616",
                iconSystemName: "book"
            ),
            isSelected: false
        )

        SDNotebookBadge(notebook: nil)
    }
    .padding()
}
