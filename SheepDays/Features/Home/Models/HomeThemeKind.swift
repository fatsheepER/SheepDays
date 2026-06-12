//
//  HomeThemeKind.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/6/12.
//

enum HomeThemeKind {
    case standard
    case memorial

    init(page: HomeContentPage) {
        switch page {
        case .expiredMemorials:
            self = .memorial
        case .upcoming:
            self = .standard
        }
    }

    var theme: SheepDaysTheme {
        switch self {
        case .standard:
            return .standard
        case .memorial:
            return .memorial
        }
    }
}
