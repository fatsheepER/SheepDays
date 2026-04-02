//
//  HomeDateDisplayContent.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/2.
//

import Foundation

struct HomeDateDisplayContent {
    let referenceDate: Date
    let yearText: String
    let monthText: String
    let separatorText: String
    let dayText: String
    let dayOffsetFromToday: Int
    let badgeText: String

    init(referenceDate: Date, today: Date = .now, calendar: Calendar = .current) {
        let normalizedReferenceDate = calendar.startOfDay(for: referenceDate)
        let normalizedToday = calendar.startOfDay(for: today)
        let monthFormatter = DateFormatter()
        let yearFormatter = DateFormatter()

        monthFormatter.calendar = calendar
        monthFormatter.locale = .current
        monthFormatter.setLocalizedDateFormatFromTemplate("MMMM")

        yearFormatter.calendar = calendar
        yearFormatter.locale = .current
        yearFormatter.setLocalizedDateFormatFromTemplate("yyyy")

        self.referenceDate = normalizedReferenceDate
        self.yearText = yearFormatter.string(from: normalizedReferenceDate)
        self.monthText = monthFormatter.string(from: normalizedReferenceDate)
        self.separatorText = ","
        self.dayText = String(calendar.component(.day, from: normalizedReferenceDate))
        self.dayOffsetFromToday = calendar.dateComponents([.day], from: normalizedToday, to: normalizedReferenceDate).day ?? 0
        self.badgeText = Self.makeBadgeText(for: dayOffsetFromToday)
    }

    private static func makeBadgeText(for dayOffsetFromToday: Int) -> String {
        switch dayOffsetFromToday {
        case 0:
            return "Today"
        case let value where value > 0:
            return "+\(value)"
//            return "\(value) Days"
        default:
            return "\(dayOffsetFromToday)"
        }
    }
}
