//
//  SheepDaysTheme.swift
//  SheepDays
//
//  Created by Codex on 2026/6/4.
//

import SwiftUI

struct SheepDaysTheme {
    let accentColor: Color
    let secondaryAccentColor: Color

    init(accentColor: Color, secondaryAccentColor: Color? = nil) {
        self.accentColor = accentColor
        self.secondaryAccentColor = secondaryAccentColor ?? accentColor.opacity(0.2)
    }
}

extension SheepDaysTheme {
    static let standard = SheepDaysTheme(
        accentColor: .sheepDaysAccent,
        secondaryAccentColor: .sheepDaysSecondaryAccent
    )

    static let memorial = SheepDaysTheme(
        accentColor: .sheepDaysMemorialAccent,
        secondaryAccentColor: .sheepDaysSecondaryMemorialAccent
    )
}

private struct SheepDaysThemeKey: EnvironmentKey {
    static let defaultValue = SheepDaysTheme.standard
}

extension EnvironmentValues {
    var sheepDaysTheme: SheepDaysTheme {
        get { self[SheepDaysThemeKey.self] }
        set { self[SheepDaysThemeKey.self] = newValue }
    }
}

extension View {
    func sheepDaysTheme(_ theme: SheepDaysTheme) -> some View {
        environment(\.sheepDaysTheme, theme)
            .tint(theme.accentColor)
    }
}

extension Color {
    static let sheepDaysAccent = Color("AccentColor")
    static let sheepDaysSecondaryAccent = Color("SecondaryAccentColor")
    static let sheepDaysMemorialAccent = Color("MemorialAccentColor")
    static let sheepDaysSecondaryMemorialAccent = Color("SecondaryMemorialAccentColor")

    static let accentColorSecondary = sheepDaysSecondaryAccent
}
