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
    fileprivate let semanticRole: SDSheetActionButtonAppearanceSemanticRole?

    init(
        backgroundColor: Color,
        titleForegroundColor: Color,
        iconForegroundColor: Color? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.titleForegroundColor = titleForegroundColor
        self.iconForegroundColor = iconForegroundColor ?? titleForegroundColor
        self.semanticRole = nil
    }

    fileprivate init(
        backgroundColor: Color,
        titleForegroundColor: Color,
        iconForegroundColor: Color? = nil,
        semanticRole: SDSheetActionButtonAppearanceSemanticRole
    ) {
        self.backgroundColor = backgroundColor
        self.titleForegroundColor = titleForegroundColor
        self.iconForegroundColor = iconForegroundColor ?? titleForegroundColor
        self.semanticRole = semanticRole
    }

    fileprivate func resolved(with theme: SheepDaysTheme) -> SDSheetActionButtonAppearance {
        switch semanticRole {
        case .themeProminent:
            return SDSheetActionButtonAppearance(
                backgroundColor: theme.secondaryAccentColor,
                titleForegroundColor: theme.accentColor
            )
        case nil:
            return self
        }
    }
}

fileprivate enum SDSheetActionButtonAppearanceSemanticRole {
    case themeProminent
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
        backgroundColor: .sheepDaysSecondaryAccent,
        titleForegroundColor: .sheepDaysAccent,
        semanticRole: .themeProminent
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
    @Environment(\.sheepDaysTheme) private var theme

    let iconSystemName: String?
    let title: String
    let placement: SDSheetActionButtonPlacement
    let appearance: SDSheetActionButtonAppearance

    init(
        iconSystemName: String? = nil,
        title: String,
        placement: SDSheetActionButtonPlacement,
        appearance: SDSheetActionButtonAppearance = .plain
    ) {
        self.iconSystemName = iconSystemName
        self.title = title
        self.placement = placement
        self.appearance = appearance
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
        self.appearance = SDSheetActionButtonAppearance(
            backgroundColor: backgroundColor,
            titleForegroundColor: titleForegroundColor,
            iconForegroundColor: iconForegroundColor
        )
    }

    var body: some View {
        let resolvedAppearance = appearance.resolved(with: theme)

        HStack(spacing: 6) {
            if let iconSystemName {
                Image(systemName: iconSystemName)
                    .foregroundStyle(resolvedAppearance.iconForegroundColor)
            }

            Text(title)
                .foregroundStyle(resolvedAppearance.titleForegroundColor)
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
                color: resolvedAppearance.backgroundColor
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
            backgroundColor: .sheepDaysSecondaryAccent,
            titleForegroundColor: .sheepDaysAccent,
            iconForegroundColor: .green
        )
        .font(.system(size: 16, weight: .semibold, design: .rounded))
    }
    .padding()
    .background(Color(.secondarySystemBackground).ignoresSafeArea())
}
