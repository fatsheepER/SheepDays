//
//  HomeRelativeValuePrompt.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/6/12.
//

import Foundation

struct HomeRelativeValuePrompt: Identifiable {
    let id = UUID()
    let targetDate: Date
    let mode: HomeRelativeValueMode

    func referenceDate(
        forRelativeDayOffset relativeDayOffset: Int,
        calendar: Calendar
    ) -> Date? {
        mode.referenceDate(
            targetDate: targetDate,
            relativeDayOffset: relativeDayOffset,
            calendar: calendar
        )
    }
}

enum HomeRelativeValueMode {
    case remainingDays
    case elapsedDays

    init(page: HomeContentPage) {
        switch page {
        case .upcoming:
            self = .remainingDays
        case .expiredMemorials:
            self = .elapsedDays
        }
    }

    func referenceDate(
        targetDate: Date,
        relativeDayOffset: Int,
        calendar: Calendar
    ) -> Date? {
        switch self {
        case .remainingDays:
            return calendar.date(byAdding: .day, value: -relativeDayOffset, to: targetDate)
        case .elapsedDays:
            return calendar.date(byAdding: .day, value: relativeDayOffset, to: targetDate)
        }
    }
}
