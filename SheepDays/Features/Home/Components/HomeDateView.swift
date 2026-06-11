//
//  HomeDateView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/2.
//

import SwiftUI

struct HomeDateView: View {
    @Environment(\.sheepDaysTheme) private var theme

    private let content: HomeDateDisplayContent
    private let weekContent: HomeWeekDisplayContent

    init(referenceDate: Date, today: Date = .now, calendar: Calendar = .current, locale: Locale = .current) {
        self.content = HomeDateDisplayContent(
            referenceDate: referenceDate,
            today: today,
            calendar: calendar,
            locale: locale
        )
        self.weekContent = HomeWeekDisplayContent(
            referenceDate: referenceDate,
            calendar: calendar
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Text(content.dayText)
                    .contentTransition(.numericText())
                    .font(.system(size: 55, weight: .bold))
                    .foregroundStyle(theme.accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: 68, alignment: .leading)

                Text(content.monthText)
                    .contentTransition(.numericText())
                    .font(monthTextFont)
                    .foregroundStyle(monthTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if content.dayOffsetFromToday != 0 {
                    SDIncreBadge(text: content.badgeText)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HomeWeekStripView(week: weekContent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var monthTextFont: Font {
        if content.locale.isChineseLanguage {
            return .system(size: 30, weight: .medium)
        }

        return .system(size: 30, weight: .semibold)
    }

    private var monthTextColor: Color {
        content.locale.isChineseLanguage ? .primary : .secondary
    }
}

private extension Locale {
    var isChineseLanguage: Bool {
        language.languageCode?.identifier == "zh"
    }
}

private enum HomeWeekPageDirection {
    case forward
    case backward

    var insertionEdge: Edge {
        switch self {
        case .forward:
            return .trailing
        case .backward:
            return .leading
        }
    }

    var removalEdge: Edge {
        switch self {
        case .forward:
            return .leading
        case .backward:
            return .trailing
        }
    }
}

private struct HomeWeekDisplayContent: Equatable {
    let weekStartDate: Date
    let selectedDate: Date
    let days: [HomeWeekDay]

    init(referenceDate: Date, calendar: Calendar) {
        let selectedDate = calendar.startOfDay(for: referenceDate)
        let weekStartDate = calendar.startOfNaturalWeek(containing: selectedDate)
        let weekdayFormatter = DateFormatter()

        weekdayFormatter.calendar = calendar
        weekdayFormatter.locale = Locale(identifier: "en_US_POSIX")
        weekdayFormatter.timeZone = calendar.timeZone
        weekdayFormatter.dateFormat = "EEE"

        self.weekStartDate = weekStartDate
        self.selectedDate = selectedDate
        self.days = (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: weekStartDate) ?? weekStartDate

            return HomeWeekDay(
                date: date,
                dayText: String(calendar.component(.day, from: date)),
                weekdayText: weekdayFormatter.string(from: date).uppercased(),
                isSelected: calendar.isDate(date, inSameDayAs: selectedDate)
            )
        }
    }
}

private struct HomeWeekDay: Identifiable, Equatable {
    let date: Date
    let dayText: String
    let weekdayText: String
    let isSelected: Bool

    var id: Date { date }
}

private struct HomeWeekStripView: View {
    let week: HomeWeekDisplayContent

    @Namespace private var selectionNamespace
    @State private var displayedWeek: HomeWeekDisplayContent
    @State private var pageDirection: HomeWeekPageDirection = .forward

    init(week: HomeWeekDisplayContent) {
        self.week = week
        _displayedWeek = State(initialValue: week)
    }

    var body: some View {
        ZStack {
            HomeWeekPageView(
                week: displayedWeek,
                selectionNamespace: selectionNamespace
            )
            .id(displayedWeek.weekStartDate)
            .transition(pageTransition)
        }
        .frame(height: 60)
        .clipped()
        .onChange(of: week) { oldWeek, newWeek in
            updateDisplayedWeek(from: oldWeek, to: newWeek)
        }
    }

    private var pageTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: pageDirection.insertionEdge).combined(with: .opacity),
            removal: .move(edge: pageDirection.removalEdge).combined(with: .opacity)
        )
    }

    private func updateDisplayedWeek(from oldWeek: HomeWeekDisplayContent, to newWeek: HomeWeekDisplayContent) {
        pageDirection = newWeek.selectedDate >= oldWeek.selectedDate ? .forward : .backward

        let animation: Animation = newWeek.weekStartDate == displayedWeek.weekStartDate
            ? .snappy(duration: 0.22)
            : .smooth(duration: 0.26)

        withAnimation(animation) {
            displayedWeek = newWeek
        }
    }
}

private struct HomeWeekPageView: View {
    let week: HomeWeekDisplayContent
    let selectionNamespace: Namespace.ID

    var body: some View {
        HStack(spacing: 5) {
            ForEach(week.days) { day in
                HomeWeekDayBlock(
                    day: day,
                    selectionNamespace: selectionNamespace
                )
            }
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct HomeWeekDayBlock: View {
    @Environment(\.sheepDaysTheme) private var theme

    let day: HomeWeekDay
    let selectionNamespace: Namespace.ID

    var body: some View {
        VStack(spacing: 3) {
            Text(day.dayText)
                .contentTransition(.numericText())
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(day.isSelected ? Color.primary : Color.secondary)
                .lineLimit(1)
                .frame(width: 30)

            Text(day.weekdayText)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(theme.accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(5)
        .background(alignment: .center) {
            if day.isSelected {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(Color(.quaternarySystemFill))
                    .matchedGeometryEffect(id: "selected-week-day-background", in: selectionNamespace)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

private extension Calendar {
    func startOfNaturalWeek(containing date: Date) -> Date {
        let normalizedDate = startOfDay(for: date)
        let weekday = component(.weekday, from: normalizedDate)
        let daysFromWeekStart = (weekday - firstWeekday + 7) % 7

        return self.date(byAdding: .day, value: -daysFromWeekStart, to: normalizedDate) ?? normalizedDate
    }
}

#Preview {
    VStack(spacing: 12) {
        HomeDateView(referenceDate: .now)
        HomeDateView(referenceDate: Calendar.current.date(byAdding: .day, value: 4, to: .now) ?? .now)
        HomeDateView(referenceDate: Calendar.current.date(byAdding: .day, value: -5, to: .now) ?? .now)
        HomeDateView(referenceDate: Calendar.current.date(byAdding: .year, value: 2, to: .now) ?? .now)
    }
    .padding()
}
