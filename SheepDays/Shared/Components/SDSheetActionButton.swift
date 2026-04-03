//
//  SDSheetActionButton.swift
//  SheepDays
//
//  Created by Codex on 2026/4/2.
//

import SwiftUI

enum SDSheetActionButtonPlacement {
    case left
    case middle
    case right
}

enum SDSheetActionButtonStyle {
    case plain
    case prominent
    case destructive
}

struct SDSheetActionButton: View {
    let iconSystemName: String?
    let title: String
    let placement: SDSheetActionButtonPlacement
    let style: SDSheetActionButtonStyle

    init(
        iconSystemName: String? = nil,
        title: String,
        placement: SDSheetActionButtonPlacement,
        style: SDSheetActionButtonStyle
    ) {
        self.iconSystemName = iconSystemName
        self.title = title
        self.placement = placement
        self.style = style
    }

    var body: some View {
        HStack(spacing: 3) {
            if let iconSystemName {
                Image(systemName: iconSystemName)
            }

            Text(title)
        }
        .font(.system(size: 20, weight: .semibold, design: .rounded))
        .foregroundStyle(foregroundColor)
        .frame(maxWidth: .infinity, maxHeight: 60)
        .background(
            SDRoundedBackground(
                topLeading: 10,
                topTrailing: 10,
                bottomLeading: bottomLeadingRadius,
                bottomTrailing: bottomTrailingRadius,
                cornerStyle: .continuous,
                color: backgroundColor
            )
        )
    }
}

private extension SDSheetActionButton {
    var bottomLeadingRadius: CGFloat {
        switch placement {
        case .left:
            return 35
        case .middle, .right:
            return 10
        }
    }

    var bottomTrailingRadius: CGFloat {
        switch placement {
        case .right:
            return 35
        case .left, .middle:
            return 10
        }
    }

    var foregroundColor: Color {
        switch style {
        case .plain:
            return Color(.secondaryLabel)
        case .prominent:
            return .accentColor
        case .destructive:
            return .red
        }
    }

    var backgroundColor: Color {
        switch style {
        case .plain:
            return Color(.secondarySystemBackground)
        case .prominent:
            return .accentColorSecondary
        case .destructive:
            return Color.red.opacity(0.15)
        }
    }
}

#Preview {
    HStack {
        SDSheetActionButton(
            iconSystemName: "arrow.left",
            title: "返回",
            placement: .left,
            style: .plain
        )

        SDSheetActionButton(
            iconSystemName: "tray",
            title: "存草稿",
            placement: .middle,
            style: .destructive
        )

        SDSheetActionButton(
            iconSystemName: "checkmark",
            title: "保存",
            placement: .right,
            style: .prominent
        )
    }
    .padding()
}
