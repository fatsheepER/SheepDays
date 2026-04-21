//
//  HomeReferenceDate.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/21.
//

import Foundation

enum HomeReferenceDate {
    static func normalized(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }
}
