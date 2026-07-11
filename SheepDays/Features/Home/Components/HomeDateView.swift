//
//  HomeDateView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/2.
//

import SwiftUI

struct HomeDateView: View {
    @Environment(\.sheepDaysTheme) private var theme
    @Binding private var referenceDate: Date

    private let dateScrubState: HomeDateScrubState?
    private let today: Date
    private let calendar: Calendar
    private let locale: Locale

    init(
        referenceDate: Binding<Date>,
        dateScrubState: HomeDateScrubState? = nil,
        today: Date = .now,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) {
        _referenceDate = referenceDate
        self.dateScrubState = dateScrubState
        self.today = today
        self.calendar = calendar
        self.locale = locale
    }

    init(
        referenceDate: Date,
        dateScrubState: HomeDateScrubState? = nil,
        today: Date = .now,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) {
        self.init(
            referenceDate: .constant(referenceDate),
            dateScrubState: dateScrubState,
            today: today,
            calendar: calendar,
            locale: locale
        )
    }

    var body: some View {
        let content = self.content
        let dateStripContent = self.dateStripContent

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Text(content.dayText)
                    .contentTransition(.numericText())
                    .font(.system(size: 55, weight: .bold, design: .rounded))
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

            HomeDateStripView(
                content: dateStripContent,
                calendar: calendar,
                dateScrubState: dateScrubState,
                selectDate: selectDate
            )
            .padding(.vertical, 5)
            .clipShape(Capsule(style: .continuous))
            .glassEffect(
                .regular.interactive(),
                in: Capsule(style: .continuous)
            )

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

    private var dateStripContent: HomeDateStripDisplayContent {
        HomeDateStripDisplayContent(
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

private enum HomeDateStripLayout {
    static let visibleDayRadius = 3
    static let renderedDayRadius = 6
    static let spacing: CGFloat = 5

    static var visibleDayCount: Int {
        visibleDayRadius * 2 + 1
    }
}

private struct HomeDateStripDisplayContent: Equatable {
    let selectedDate: Date
    let days: [HomeDateStripDay]

    init(referenceDate: Date, today: Date = .now, calendar: Calendar) {
        let selectedDate = calendar.startOfDay(for: referenceDate)
        let today = calendar.startOfDay(for: today)
        let weekdayFormatter = DateFormatter()

        weekdayFormatter.calendar = calendar
        weekdayFormatter.locale = Locale(identifier: "en_US_POSIX")
        weekdayFormatter.timeZone = calendar.timeZone
        weekdayFormatter.dateFormat = "EEE"

        self.selectedDate = selectedDate
        self.days = (-HomeDateStripLayout.renderedDayRadius...HomeDateStripLayout.renderedDayRadius).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: selectedDate) ?? selectedDate

            return HomeDateStripDay(
                date: date,
                dayText: String(calendar.component(.day, from: date)),
                weekdayText: weekdayFormatter.string(from: date).uppercased(),
                isToday: calendar.isDate(date, inSameDayAs: today)
            )
        }
    }
}

private struct HomeDateStripDay: Identifiable, Equatable {
    let date: Date
    let dayText: String
    let weekdayText: String
    let isToday: Bool

    var id: Date { date }
}

private struct HomeDateStripView: View {
    let content: HomeDateStripDisplayContent
    let calendar: Calendar
    let dateScrubState: HomeDateScrubState?
    let selectDate: (Date) -> Void

    @State private var displayedContent: HomeDateStripDisplayContent
    @State private var displayedSelectedDate: Date
    @State private var animatedDayOffset = 0
    @State private var displayedPageOffset: CGFloat = 0
    @State private var incomingContent: HomeDateStripDisplayContent?
    @State private var incomingPageOffset: CGFloat = 0
    @State private var animationGeneration = 0

    init(
        content: HomeDateStripDisplayContent,
        calendar: Calendar,
        dateScrubState: HomeDateScrubState?,
        selectDate: @escaping (Date) -> Void
    ) {
        self.content = content
        self.calendar = calendar
        self.dateScrubState = dateScrubState
        self.selectDate = selectDate
        _displayedContent = State(initialValue: content)
        _displayedSelectedDate = State(initialValue: content.selectedDate)
    }

    var body: some View {
        let scrubSnapshot = dateScrubState?.snapshot ?? .idle

        ZStack {
            HomeDateStripSelectionBackground()

            GeometryReader { geometry in
                let dayWidth = dayWidth(in: geometry.size.width)
                let stripWidth = stripWidth(dayWidth: dayWidth)

                ZStack {
                    HomeDateStripPage(
                        content: displayedContent,
                        selectedDate: displayedSelectedDate,
                        calendar: calendar,
                        dayWidth: dayWidth,
                        stripWidth: stripWidth,
                        viewportWidth: geometry.size.width,
                        viewportHeight: geometry.size.height,
                        dayOffset: displayedDayOffset(for: scrubSnapshot),
                        pageOffset: displayedPageOffset,
                        selectDate: selectDate
                    )
                    .id(displayedContent.selectedDate)

                    if let incomingContent {
                        HomeDateStripPage(
                            content: incomingContent,
                            selectedDate: incomingContent.selectedDate,
                            calendar: calendar,
                            dayWidth: dayWidth,
                            stripWidth: stripWidth,
                            viewportWidth: geometry.size.width,
                            viewportHeight: geometry.size.height,
                            dayOffset: 0,
                            pageOffset: incomingPageOffset,
                            selectDate: selectDate
                        )
                        .id(incomingContent.selectedDate)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .allowsHitTesting(incomingContent == nil)
            }
        }
        .padding(.horizontal, 10)
//        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(height: 60)
        .transaction { transaction in
            guard scrubSnapshot.isActive else {
                return
            }

            transaction.animation = nil
            transaction.disablesAnimations = true
        }
        .onChange(of: content.selectedDate) { _, _ in
            if scrubSnapshot.isActive {
                cancelAnimationAndReset(to: content)
            } else {
                move(to: content)
            }
        }
        .onChange(of: scrubSnapshot.isActive) { _, isActive in
            guard isActive else {
                return
            }

            cancelAnimationAndReset(to: content)
        }
    }

    private func displayedDayOffset(for scrubSnapshot: HomeDateScrubSnapshot) -> Double {
        if scrubSnapshot.isActive {
            return scrubSnapshot.residualDayOffset
        }

        return Double(animatedDayOffset)
    }

    private func dayWidth(in availableWidth: CGFloat) -> CGFloat {
        let totalSpacing = CGFloat(HomeDateStripLayout.visibleDayCount - 1) * HomeDateStripLayout.spacing
        return max((availableWidth - totalSpacing) / CGFloat(HomeDateStripLayout.visibleDayCount), 0)
    }

    private func stripWidth(dayWidth: CGFloat) -> CGFloat {
        let dayCount = displayedContent.days.count
        let totalSpacing = CGFloat(dayCount - 1) * HomeDateStripLayout.spacing
        return CGFloat(dayCount) * dayWidth + totalSpacing
    }

    private func move(to newContent: HomeDateStripDisplayContent) {
        if let incomingContent {
            reset(to: incomingContent)
        }

        animationGeneration += 1
        let generation = animationGeneration

        let dayOffset = calendar.dateComponents(
            [.day],
            from: displayedContent.selectedDate,
            to: newContent.selectedDate
        ).day ?? 0

        guard dayOffset != 0 else {
            reset(to: newContent)
            return
        }

        guard abs(dayOffset) <= HomeDateStripLayout.visibleDayRadius else {
            moveAcrossPage(
                to: newContent,
                direction: dayOffset.signum(),
                generation: generation
            )
            return
        }

        displayedSelectedDate = newContent.selectedDate

        withAnimation(.default, completionCriteria: .logicallyComplete) {
            animatedDayOffset = dayOffset
        } completion: {
            guard animationGeneration == generation else {
                return
            }

            reset(to: newContent)
        }
    }

    private func moveAcrossPage(
        to newContent: HomeDateStripDisplayContent,
        direction: Int,
        generation: Int
    ) {
        let pageDirection = CGFloat(direction)
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            displayedSelectedDate = displayedContent.selectedDate
            animatedDayOffset = 0
            displayedPageOffset = 0
            incomingContent = newContent
            incomingPageOffset = pageDirection
        }

        withAnimation(.default, completionCriteria: .logicallyComplete) {
            displayedPageOffset = -pageDirection
            incomingPageOffset = 0
        } completion: {
            guard animationGeneration == generation else {
                return
            }

            reset(to: newContent)
        }
    }

    private func reset(to newContent: HomeDateStripDisplayContent) {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            displayedContent = newContent
            displayedSelectedDate = newContent.selectedDate
            animatedDayOffset = 0
            displayedPageOffset = 0
            incomingContent = nil
            incomingPageOffset = 0
        }
    }

    private func cancelAnimationAndReset(to newContent: HomeDateStripDisplayContent) {
        animationGeneration += 1
        reset(to: newContent)
    }
}

private struct HomeDateStripPage: View {
    let content: HomeDateStripDisplayContent
    let selectedDate: Date
    let calendar: Calendar
    let dayWidth: CGFloat
    let stripWidth: CGFloat
    let viewportWidth: CGFloat
    let viewportHeight: CGFloat
    let dayOffset: Double
    let pageOffset: CGFloat
    let selectDate: (Date) -> Void

    var body: some View {
        ZStack {
            HomeDateStripDaysLayer(
                content: content,
                selectedDate: selectedDate,
                calendar: calendar,
                dayWidth: dayWidth,
                selectDate: selectDate
            )
            .frame(width: stripWidth, height: viewportHeight)
            .offset(
                x: -CGFloat(dayOffset)
                    * (dayWidth + HomeDateStripLayout.spacing)
            )
        }
        .frame(width: viewportWidth, height: viewportHeight)
        .clipped()
        .offset(x: pageOffset * viewportWidth)
    }
}

private struct HomeDateStripDaysLayer: View {
    let content: HomeDateStripDisplayContent
    let selectedDate: Date
    let calendar: Calendar
    let dayWidth: CGFloat
    let selectDate: (Date) -> Void

    var body: some View {
        HStack(spacing: HomeDateStripLayout.spacing) {
            ForEach(content.days) { day in
                HomeDateBlock(
                    day: day,
                    isSelected: calendar.isDate(day.date, inSameDayAs: selectedDate),
                    selectDate: selectDate
                )
                .frame(width: dayWidth)
            }
        }
    }
}

private struct HomeDateStripSelectionBackground: View {
    private static let selectedOffset = 0

    var body: some View {
        HStack(spacing: HomeDateStripLayout.spacing) {
            ForEach(-HomeDateStripLayout.visibleDayRadius...HomeDateStripLayout.visibleDayRadius, id: \.self) { dayOffset in
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(dayOffset == Self.selectedOffset ? Color(.quaternarySystemFill) : .clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct HomeDateBlock: View {
    @Environment(\.sheepDaysTheme) private var theme

    let day: HomeDateStripDay
    let isSelected: Bool
    let selectDate: (Date) -> Void

    var body: some View {
        Button {
            selectDate(day.date)
        } label: {
            VStack(spacing: 3) {
                Text(day.dayText)
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
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(day.weekdayText) \(day.dayText)"))
    }

    private var dayTextColor: Color {
        if day.isToday {
            return theme.accentColor
        }

        return isSelected ? .primary : .secondary
    }
}

#Preview {
    @Previewable @State var date = Date()

    VStack(spacing: 12) {
        HomeDateView(referenceDate: $date)
        HomeDateView(referenceDate: Calendar.current.date(byAdding: .day, value: 4, to: .now) ?? .now)
    }
    .padding()
    .background {
        Color(.systemGroupedBackground)
    }
}
