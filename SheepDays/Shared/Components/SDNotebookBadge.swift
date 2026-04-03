//
//  SDNotebookBadge.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/2.
//

import SwiftUI

struct SDNotebookBadge: View {
    let notebook: Notebook?

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

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Image(systemName: iconSystemName)
            Text(title)
        }
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(.white)
        .padding(10)
        .background(
            SDRoundedBackground(
                topLeading: 15,
                topTrailing: 15,
                bottomLeading: 15,
                bottomTrailing: 5,
                cornerStyle: .continuous,
                color: tintColor
            )
        )
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        SDNotebookBadge(
            notebook: Notebook(
                name: "家庭",
                colorHex: "FF8A65",
                iconSystemName: "house.fill"
            )
        )

        SDNotebookBadge(notebook: nil)
    }
    .padding()
}
