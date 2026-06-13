//
//  NotebookSummaryCard.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/9.
//

import SwiftUI

struct NotebookSummaryCardFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, next in next })
    }
}

struct NotebookSummaryCard: View {
    let summary: NotebookSummary
    let isEditing: Bool
    var reportsFrame = true
    var showsEventPreview = true
    @Binding var isExpanded: Bool
    let onAccessoryTap: () -> Void
    let onTap: () -> Void

    @State private var shouldSuppressCardTap = false

    private var accentColor: Color {
        summary.notebook.tintColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            NotebookSummaryCardHeader(
                notebook: summary.notebook,
                futureEventCount: summary.futureEventCount,
                accentColor: accentColor
            )

            NotebookDailyGraph(
                eventDays: summary.eventDays,
                today: summary.today,
                accentColor: accentColor
            )

            if showsEventPreview {
                NotebookSummaryEventPreviewSection(
                    summary: summary,
                    isExpanded: $isExpanded,
                    onToggleExpanded: suppressNextCardTap
                )
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    )
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            baseCardBackground
        }
        .clipShape(
            SDRoundedCornersShape(
                topLeading: 30,
                topTrailing: 30,
                bottomLeading: 30,
                bottomTrailing: 10,
                style: .continuous
            )
        )
        .contentShape(
            SDRoundedCornersShape(
                topLeading: 30,
                topTrailing: 30,
                bottomLeading: 30,
                bottomTrailing: 10,
                style: .continuous
            )
        )
        .onTapGesture {
            guard !shouldSuppressCardTap else {
                shouldSuppressCardTap = false
                return
            }

            if isEditing {
                onAccessoryTap()
            } else {
                onTap()
            }
        }
        .background {
            framePreferenceReporter
        }
        .animation(.snappy(duration: 0.32, extraBounce: 0), value: showsEventPreview)
    }

    var baseCardBackground: some View {
        SDRoundedBackground(
            topLeading: 30,
            topTrailing: 30,
            bottomLeading: 30,
            bottomTrailing: 10,
            color: Color(.secondarySystemGroupedBackground)
        )
    }

    func suppressNextCardTap() {
        shouldSuppressCardTap = true

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            shouldSuppressCardTap = false
        }
    }

    @ViewBuilder
    var framePreferenceReporter: some View {
        if reportsFrame {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: NotebookSummaryCardFramePreferenceKey.self,
                    value: [summary.id: proxy.frame(in: .global)]
                )
            }
        } else {
            Color.clear
        }
    }
}

private struct NotebookSummaryCardHeader: View {
    let notebook: Notebook
    let futureEventCount: Int
    let accentColor: Color

    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: notebook.iconSystemName ?? "book.closed")
                    .font(.system(size: 30, weight: .medium, design: .rounded))
                    .frame(width: 43, height: 35)
                    .accessibilityHidden(true)

                Text(notebook.name)
                    .font(.system(size: 30, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(accentColor)
            .frame(maxWidth: .infinity, alignment: .leading)

            NotebookFutureCountBadge(
                count: futureEventCount,
                accentColor: accentColor
            )
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 10)
        .frame(minHeight: 55)
    }
}

private struct NotebookFutureCountBadge: View {
    let count: Int
    let accentColor: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("\(count)")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .contentTransition(.numericText())

            Text("个未来的事件")
                .font(.system(size: 15, weight: .semibold))
        }
        .foregroundStyle(accentColor)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(10)
        .accessibilityLabel("\(count) 个未来的事件")
    }
}

private struct NotebookDailyGraph: View {
    let eventDays: Set<Date>
    let today: Date
    let accentColor: Color

    private let indicatorWidth: CGFloat = 3
    private let indicatorHeight: CGFloat = 30
    private let indicatorSpacing: CGFloat = 7
    private let triangleSize: CGFloat = 10

    var body: some View {
        GeometryReader { geometry in
            let indicatorOffsets = indicatorOffsets(for: geometry.size.width)

            VStack(spacing: 3) {
                NotebookTodayTriangle(direction: .down)
                    .fill(Color(.tertiaryLabel))
                    .frame(width: triangleSize, height: triangleSize)

                HStack(spacing: indicatorSpacing) {
                    ForEach(indicatorOffsets, id: \.self) { dayOffset in
                        indicator(for: dayOffset)
                    }
                }
                .frame(maxWidth: .infinity)

                NotebookTodayTriangle(direction: .up)
                    .fill(Color(.tertiaryLabel))
                    .frame(width: triangleSize, height: triangleSize)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(height: 66)
        .padding(.vertical, 5)
    }

    func indicatorOffsets(for width: CGFloat) -> [Int] {
        let pitch = indicatorWidth + indicatorSpacing + 0.5
        let rawCount = max(7, Int((width / pitch).rounded(.down)))
        let oddCount = rawCount.isMultiple(of: 2) ? rawCount - 1 : rawCount
        let radius = max(3, oddCount / 2)

        return Array((-radius)...radius)
    }

    func indicator(for dayOffset: Int) -> some View {
        let isToday = dayOffset == 0

        return Capsule()
            .fill(indicatorFill(for: dayOffset))
            .frame(width: indicatorWidth, height: indicatorHeight)
            .overlay {
                if isToday {
                    Capsule()
                        .stroke(Color(.secondaryLabel), lineWidth: 1)
                }
            }
            .accessibilityHidden(true)
    }

    func indicatorFill(for dayOffset: Int) -> Color {
        guard dayOffset != 0,
              let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: today),
              eventDays.contains(Calendar.current.startOfDay(for: date)) else {
            return Color(.quaternaryLabel)
        }

        return dayOffset < 0 ? accentColor.opacity(0.2) : accentColor
    }
}

private struct NotebookSummaryEventPreviewSection: View {
    let summary: NotebookSummary
    @Binding var isExpanded: Bool
    let onToggleExpanded: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let nextEvent = summary.nextEvent {
                NotebookSummarySectionTitle(title: isExpanded ? "一周内" : "下一个")

                ForEach(displayedEvents(fallback: nextEvent)) { event in
                    HomeDisplayItemView(
                        item: displayItem(for: event),
                        visibleStateIndicators: .notebookDetail
                    )
                }

                if shouldShowExpandButton {
                    expandButton
                }
            } else {
                NotebookSummarySectionTitle(title: emptyTitle)
            }
        }
        .animation(.snappy(duration: 0.25), value: isExpanded)
    }

    var shouldShowExpandButton: Bool {
        isExpanded || summary.additionalWeekEventCount > 0
    }

    var emptyTitle: String {
        if summary.pastEventCount > 0 {
            return "已经历 \(summary.pastEventCount) 个事件"
        }

        return "无事件"
    }

    @ViewBuilder
    var expandButton: some View {
        Button {
            onToggleExpanded()

            withAnimation(.snappy(duration: 0.25)) {
                isExpanded.toggle()
            }
        } label: {
            Text(isExpanded ? "收起" : "一周内还有 \(summary.additionalWeekEventCount) 个更多")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(.tertiaryLabel))
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(isExpanded ? "收起一周内事件" : "展开一周内事件")
    }

    func displayedEvents(fallback nextEvent: Event) -> [Event] {
        if isExpanded {
            return summary.weekEvents
        }

        return [nextEvent]
    }

    func displayItem(for event: Event) -> HomeDisplayItem {
        let dateDisplay = HomeDateDisplayContent(referenceDate: event.targetDate, today: summary.today)

        return HomeDisplayItem(
            id: event.id,
            sourceEventId: event.id,
            title: event.title,
            iconSystemName: event.iconSystemName,
            tintHex: summary.notebook.colorHex,
            badgeText: dateDisplay.badgeText,
            isToday: dateDisplay.dayOffsetFromToday == 0,
            stateIndicators: stateIndicators(for: event),
            sortKey: Double(dateDisplay.dayOffsetFromToday),
            groupKey: nil
        )
    }

    func stateIndicators(for event: Event) -> Set<HomeDisplayItemStateIndicator> {
        var indicators: Set<HomeDisplayItemStateIndicator> = []

        if event.hasChecklistItems {
            indicators.insert(.checklist)
        }

        if !event.reminderPresets.isEmpty {
            indicators.insert(.reminder)
        }

        if event.showOnHome {
            indicators.insert(.showOnHome)
        }

        if event.pinToTop {
            indicators.insert(.pinned)
        }

        return indicators
    }
}

private struct NotebookSummarySectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color(.secondaryLabel))
            .lineLimit(1)
            .padding(.horizontal, 5)
    }
}

private struct NotebookTodayTriangle: Shape {
    enum Direction {
        case up
        case down
    }

    let direction: Direction

    func path(in rect: CGRect) -> Path {
        var path = Path()

        switch direction {
        case .up:
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        case .down:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }

        path.closeSubpath()
        return path
    }
}

#Preview {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)

    let notebook = Notebook(
        name: "比赛",
        colorHex: "00AEB3",
        iconSystemName: "sportscourt"
    )

    let previewEvents = [
        Event(
            title: "即将发生的事件",
            targetDate: today,
            allDay: true,
            notebook: notebook
        ),
        Event(
            title: "半决赛",
            targetDate: calendar.date(byAdding: .day, value: 3, to: today) ?? today,
            allDay: true,
            notebook: notebook
        ),
        Event(
            title: "决赛",
            targetDate: calendar.date(byAdding: .day, value: 7, to: today) ?? today,
            allDay: true,
            notebook: notebook
        )
    ]

    VStack(spacing: 20) {
        NotebookSummaryCard(
            summary: NotebookSummary(
                notebook: notebook,
                events: previewEvents,
                futureEventCount: 2,
                pastEventCount: 4,
                weekEvents: previewEvents,
                nextEvent: previewEvents.first,
                eventDays: Set(previewEvents.map { calendar.startOfDay(for: $0.targetDate) }),
                today: today
            ),
            isEditing: false,
            isExpanded: .constant(false),
            onAccessoryTap: {},
            onTap: {}
        )

        NotebookSummaryCard(
            summary: NotebookSummary(
                notebook: Notebook(
                    name: "空事件本",
                    colorHex: "5C6BC0",
                    iconSystemName: "briefcase.fill"
                ),
                events: [],
                futureEventCount: 0,
                pastEventCount: 0,
                weekEvents: [],
                nextEvent: nil,
                eventDays: [],
                today: today
            ),
            isEditing: true,
            isExpanded: .constant(false),
            onAccessoryTap: {},
            onTap: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
