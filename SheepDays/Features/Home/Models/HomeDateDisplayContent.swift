//
//  HomeDateDisplayContent.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/2.
//

import Foundation

struct HomeDateDisplayContent {
    let referenceDate: Date
    let yearText: String?
    let monthText: String
    let separatorText: String
    let dayText: String
    let dayOfWeekText: String
    let dayOffsetFromToday: Int
    let badgeText: String

    init(referenceDate: Date, today: Date = .now, calendar: Calendar = .current, locale: Locale = .current) {
        let normalizedReferenceDate = calendar.startOfDay(for: referenceDate)
        let normalizedToday = calendar.startOfDay(for: today)
        let monthFormatter = DateFormatter()
        let yearFormatter = DateFormatter()
        let dayOfWeekFormatter = DateFormatter()
        let dayOffsetFromToday = calendar.dateComponents([.day], from: normalizedToday, to: normalizedReferenceDate).day ?? 0

        monthFormatter.calendar = calendar
        monthFormatter.locale = locale
        monthFormatter.timeZone = calendar.timeZone
        monthFormatter.setLocalizedDateFormatFromTemplate("MMMM")

        yearFormatter.calendar = calendar
        yearFormatter.locale = locale
        yearFormatter.timeZone = calendar.timeZone
        yearFormatter.setLocalizedDateFormatFromTemplate("yyyy")

        dayOfWeekFormatter.calendar = calendar
        dayOfWeekFormatter.locale = locale
        dayOfWeekFormatter.timeZone = calendar.timeZone
        dayOfWeekFormatter.setLocalizedDateFormatFromTemplate("EEEE")

        self.referenceDate = normalizedReferenceDate
        self.yearText = Self.shouldShowYear(referenceDate: normalizedReferenceDate, today: normalizedToday, calendar: calendar)
            ? yearFormatter.string(from: normalizedReferenceDate)
            : nil
        self.monthText = monthFormatter.string(from: normalizedReferenceDate)
        self.separatorText = ","
        self.dayText = String(calendar.component(.day, from: normalizedReferenceDate))
        self.dayOfWeekText = dayOfWeekFormatter.string(from: normalizedReferenceDate)
        self.dayOffsetFromToday = dayOffsetFromToday
        self.badgeText = Self.makeBadgeText(for: dayOffsetFromToday)
    }

    private static func shouldShowYear(referenceDate: Date, today: Date, calendar: Calendar) -> Bool {
        calendar.component(.year, from: referenceDate) != calendar.component(.year, from: today)
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
