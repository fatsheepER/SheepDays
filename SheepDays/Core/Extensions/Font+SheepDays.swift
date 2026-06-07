//
//  Font+SheepDays.swift
//  SheepDays
//
//  Created by Codex on 2026/6/3.
//

import SwiftUI

enum SourceHanSerifSCWeight {
    case extraLight
    case light
    case regular
    case medium
    case semiBold
    case bold
    case heavy

    var postScriptName: String {
        switch self {
        case .extraLight:
            return "SourceHanSerifSCVF-ExtraLight"
        case .light:
            return "SourceHanSerifSCVF-Light"
        case .regular:
            return "SourceHanSerifSCVF-Regular"
        case .medium:
            return "SourceHanSerifSCVF-Medium"
        case .semiBold:
            return "SourceHanSerifSCVF-SemiBold"
        case .bold:
            return "SourceHanSerifSCVF-Bold"
        case .heavy:
            return "SourceHanSerifSCVF-Heavy"
        }
    }
}

extension Font {
    static func sourceHanSerifSC(size: CGFloat, weight: SourceHanSerifSCWeight = .regular) -> Font {
        .custom(weight.postScriptName, size: size)
    }
}
