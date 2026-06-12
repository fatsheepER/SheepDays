//
//  HomeDateView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/2.
//

import SwiftUI

struct HomeDateView: View {
    @Environment(\.sheepDaysTheme) private var theme
    @Environment(\.haptics) private var haptics
    @Binding private var referenceDate: Date

    private let today: Date
    private let calendar: Calendar
    private let locale: Locale

    init(referenceDate: Binding<Date>, today: Date = .now, calendar: Calendar = .current, locale: Locale = .current) {
        _referenceDate = referenceDate
        self.today = today
        self.calendar = calendar
        self.locale = locale
    }

    init(referenceDate: Date, today: Date = .now, calendar: Calendar = .current, locale: Locale = .current) {
        self.init(
            referenceDate: .constant(referenceDate),
            today: today,
            calendar: calendar,
            locale: locale
        )
    }

    var body: some View {
        let content = self.content
        let weekContent = self.weekContent

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Text(content.dayText)
                    .contentTransition(.numericText())
                    .font(.system(size: 55, weight: .bold))
                    .foregroundStyle(theme.accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(content.monthText)
                    .contentTransition(.numericText())
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(monthTextColor)
                    .lineLimit(1)

                if content.dayOffsetFromToday != 0 {
                    SDIncreBadge(text: content.badgeText)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HomeWeekStripView(
                week: weekContent,
                calendar: calendar,
                selectDate: selectDate
            )
            .padding(.vertical, 5)
            .clipShape(Capsule(style: .continuous))
            .glassEffect(.regular.interactive(), in: Capsule(style: .continuous))

        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var content: HomeDateDisplayContent {
        HomeDateDisplayContent(
            referenceDate: referenceDate,
            today: today,
            calendar: calendar,
            locale: locale
        )
    }

    private var weekContent: HomeWeekDisplayContent {
        HomeWeekDisplayContent(
            referenceDate: referenceDate,
            today: today,
            calendar: calendar
        )
    }

    private var monthTextColor: Color {
        locale.isChineseLanguage ? .primary : .secondary
    }

    private func selectDate(_ date: Date) {
        withAnimation {
            referenceDate = calendar.startOfDay(for: date)
        }
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

    init(referenceDate: Date, today: Date = .now, calendar: Calendar) {
        let selectedDate = calendar.startOfDay(for: referenceDate)
        let today = calendar.startOfDay(for: today)
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
                isToday: calendar.isDate(date, inSameDayAs: today),
                isSelected: calendar.isDate(date, inSameDayAs: selectedDate)
            )
        }
    }
}

private struct HomeWeekDay: Identifiable, Equatable {
    let date: Date
    let dayText: String
    let weekdayText: String
    let isToday: Bool
    let isSelected: Bool

    var id: Date { date }
}

private struct HomeWeekStripView: View {
    let week: HomeWeekDisplayContent
    let calendar: Calendar
    let selectDate: (Date) -> Void

    @Environment(\.haptics) private var haptics
    
    @Namespace private var selectionNamespace
    @State private var displayedWeek: HomeWeekDisplayContent
    @State private var pageDirection: HomeWeekPageDirection = .forward
    @GestureState private var dragOffset: CGFloat = 0

    private static let swipeActivationDistance: CGFloat = 36
    private static let horizontalDominance: CGFloat = 1.15
    private static let maximumPageDragOffset: CGFloat = 56

    init(week: HomeWeekDisplayContent, calendar: Calendar, selectDate: @escaping (Date) -> Void) {
        self.week = week
        self.calendar = calendar
        self.selectDate = selectDate
        _displayedWeek = State(initialValue: week)
    }

    var body: some View {
        ZStack {
            HomeWeekPageView(
                week: displayedWeek,
                selectionNamespace: selectionNamespace,
                selectDate: selectDate
            )
            .id(displayedWeek.weekStartDate)
            .offset(x: dragOffset)
            .transition(pageTransition)
        }
        .frame(height: 60)
        .clipped()
        .contentShape(Capsule())
        .simultaneousGesture(pageDragGesture)
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

        withAnimation {
            displayedWeek = newWeek
        }
    }

    private var pageDragGesture: some Gesture {
        DragGesture(minimumDistance: 14)
            .updating($dragOffset) { value, state, _ in
                guard Self.hasHorizontalIntent(value) else {
                    return
                }

                state = min(
                    max(value.translation.width, -Self.maximumPageDragOffset),
                    Self.maximumPageDragOffset
                )
            }
            .onEnded { value in
                guard Self.hasHorizontalIntent(value) else {
                    return
                }

                let translation = dominantHorizontalTranslation(for: value)
                guard abs(translation) >= Self.swipeActivationDistance else {
                    return
                }

                haptics.play(.openDetailTap)
                moveToAdjacentWeek(translation < 0 ? 1 : -1)
            }
    }

    private static func hasHorizontalIntent(_ value: DragGesture.Value) -> Bool {
        abs(value.translation.width) > abs(value.translation.height) * horizontalDominance
    }

    private func dominantHorizontalTranslation(for value: DragGesture.Value) -> CGFloat {
        if abs(value.predictedEndTranslation.width) > abs(value.translation.width) {
            return value.predictedEndTranslation.width
        }

        return value.translation.width
    }

    private func moveToAdjacentWeek(_ weekOffset: Int) {
        guard let targetDate = calendar.date(
            byAdding: .day,
            value: weekOffset * 7,
            to: displayedWeek.weekStartDate
        ) else {
            return
        }

        selectDate(calendar.startOfDay(for: targetDate))
    }
}

private struct HomeWeekPageView: View {
    let week: HomeWeekDisplayContent
    let selectionNamespace: Namespace.ID
    let selectDate: (Date) -> Void

    var body: some View {
        HStack(spacing: 5) {
            ForEach(week.days) { day in
                HomeWeekDayBlock(
                    day: day,
                    selectionNamespace: selectionNamespace,
                    selectDate: selectDate
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
    let selectDate: (Date) -> Void

    var body: some View {
        Button {
            selectDate(day.date)
        } label: {
            VStack(spacing: 3) {
                Text(day.dayText)
                    .contentTransition(.numericText())
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(dayTextColor)
                    .lineLimit(1)
                    .frame(width: 30, alignment: .center)

                Text(day.weekdayText)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(theme.accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .center)
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
//            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(day.weekdayText) \(day.dayText)"))
    }

    private var dayTextColor: Color {
        if day.isToday {
            return theme.accentColor
        }

        return day.isSelected ? .primary : .secondary
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
    @Previewable @State var date = Date()

    VStack(spacing: 12) {
        HomeDateView(referenceDate: $date)
        HomeDateView(referenceDate: Calendar.current.date(byAdding: .day, value: 4, to: .now) ?? .now)
    }
    .padding()
}
