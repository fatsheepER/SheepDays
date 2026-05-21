//
//  FocusPresetBadge.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/5/21.
//

import SwiftUI

struct FocusPresetBadge: View {
    struct Content: Equatable {
        let id: UUID
        let title: String
        let colorHex: String
    }

    let content: Content

    private var tintColor: Color {
        Color(hex: content.colorHex) ?? .accentColor
    }

    var body: some View {
        Text(content.title)
            .lineLimit(1)
            .contentTransition(.opacity)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(tintColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule(style: .continuous)
                    .foregroundStyle(tintColor.opacity(0.2))
            }
    }
}
