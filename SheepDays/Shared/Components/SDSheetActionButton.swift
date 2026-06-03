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

struct SDSheetActionButtonAppearance {
    let backgroundColor: Color
    let titleForegroundColor: Color
    let iconForegroundColor: Color

    init(
        backgroundColor: Color,
        titleForegroundColor: Color,
        iconForegroundColor: Color? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.titleForegroundColor = titleForegroundColor
        self.iconForegroundColor = iconForegroundColor ?? titleForegroundColor
    }
}

extension SDSheetActionButtonAppearance {
    static let plain = SDSheetActionButtonAppearance(
        backgroundColor: Color(.quaternarySystemFill),
        titleForegroundColor: Color(.secondaryLabel)
    )

    static let secondary = SDSheetActionButtonAppearance(
        backgroundColor: Color(.quaternarySystemFill),
        titleForegroundColor: Color(.secondaryLabel)
    )

    static let prominent = SDSheetActionButtonAppearance(
        backgroundColor: .accent.opacity(0.1),
        titleForegroundColor: .accentColor
    )

    static let destructive = SDSheetActionButtonAppearance(
        backgroundColor: Color.red.opacity(0.1),
        titleForegroundColor: .red
    )

    static let lightTransparent = SDSheetActionButtonAppearance(
        backgroundColor: .white.opacity(0.2),
        titleForegroundColor: .white
    )
}

struct SDSheetActionButton: View {
    private static let defaultFont = Font.system(size: 18, weight: .semibold, design: .rounded)

    @Environment(\.font) private var environmentFont

    let iconSystemName: String?
    let title: String
    let placement: SDSheetActionButtonPlacement
    let backgroundColor: Color
    let titleForegroundColor: Color
    let iconForegroundColor: Color

    init(
        iconSystemName: String? = nil,
        title: String,
        placement: SDSheetActionButtonPlacement,
        appearance: SDSheetActionButtonAppearance = .plain
    ) {
        self.iconSystemName = iconSystemName
        self.title = title
        self.placement = placement
        self.backgroundColor = appearance.backgroundColor
        self.titleForegroundColor = appearance.titleForegroundColor
        self.iconForegroundColor = appearance.iconForegroundColor
    }

    init(
        iconSystemName: String? = nil,
        title: String,
        placement: SDSheetActionButtonPlacement,
        backgroundColor: Color,
        titleForegroundColor: Color,
        iconForegroundColor: Color? = nil
    ) {
        self.iconSystemName = iconSystemName
        self.title = title
        self.placement = placement
        self.backgroundColor = backgroundColor
        self.titleForegroundColor = titleForegroundColor
        self.iconForegroundColor = iconForegroundColor ?? titleForegroundColor
    }

    var body: some View {
        HStack(spacing: 6) {
            if let iconSystemName {
                Image(systemName: iconSystemName)
                    .foregroundStyle(iconForegroundColor)
            }

            Text(title)
                .foregroundStyle(titleForegroundColor)
        }
        .font(environmentFont ?? Self.defaultFont)
        .frame(maxWidth: .infinity, maxHeight: 50)
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
}

#Preview {
    HStack {
        SDSheetActionButton(
            iconSystemName: "arrow.left",
            title: "返回",
            placement: .left,
            appearance: .plain
        )

        SDSheetActionButton(
            iconSystemName: "tray",
            title: "存草稿",
            placement: .middle,
            appearance: .destructive
        )

        SDSheetActionButton(
            iconSystemName: "checkmark",
            title: "保存",
            placement: .right,
            backgroundColor: .accent.opacity(0.12),
            titleForegroundColor: .accentColor,
            iconForegroundColor: .green
        )
        .font(.system(size: 16, weight: .semibold, design: .rounded))
    }
    .padding()
    .background(Color(.secondarySystemBackground).ignoresSafeArea())
}
