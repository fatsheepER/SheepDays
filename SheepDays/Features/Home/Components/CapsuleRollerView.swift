//
//  CapsuleRollerView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2025/5/9.
//

import SwiftUI

struct CapsuleRollerView: View {
    @Environment(\.haptics) private var haptics
    @Binding private var adjustedDate: Date

    private let scrubState: HomeDateScrubState?
    private let scale: CapsuleRollerScale
    private let lineSpacing: CGFloat
    private let lineHeight: CGFloat
    private let calendar: Calendar

    private let centerDayIndex = 40
    private let lineWidth: CGFloat = 5

    @State private var scrollDayIndex: Int?
    @State private var anchorDate: Date
    @State private var currentContentOffset: CGFloat = 0
    @State private var scrollPhase: ScrollPhase = .idle
    @State private var lastAppliedDayOffset = 0
    @State private var internallyAppliedDate: Date?
    @State private var isScrubbing = false
    @State private var isRecentering = true

    init(
        adjustedDate: Binding<Date>,
        scrubState: HomeDateScrubState? = nil,
        ticksPerDay: Int = 4,
        lineSpacing: CGFloat = 5,
        lineHeight: CGFloat = 60,
        calendar: Calendar = .current
    ) {
        _adjustedDate = adjustedDate
        self.scrubState = scrubState
        self.scale = CapsuleRollerScale(ticksPerDay: ticksPerDay)
        self.lineSpacing = lineSpacing
        self.lineHeight = lineHeight
        self.calendar = calendar
        _anchorDate = State(initialValue: calendar.startOfDay(for: adjustedDate.wrappedValue))
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: lineSpacing) {
                ForEach(0...(centerDayIndex * 2), id: \.self) { dayIndex in
                    HStack(alignment: .center, spacing: lineSpacing) {
                        ForEach(0..<scale.ticksPerDay, id: \.self) { _ in
                            Capsule()
                                .frame(width: lineWidth, height: lineHeight)
                                .foregroundStyle(Color(.secondarySystemFill))
                                .scrollTransition { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1.0 : 0.1)
                                        .scaleEffect(
                                            x: phase.isIdentity ? 1.0 : 0.3,
                                            y: phase.isIdentity ? 1.0 : 0.3
                                        )
                                }
                        }
                    }
                    .id(dayIndex)
                }
            }
            .frame(height: lineHeight)
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByFew))
        .scrollPosition(id: $scrollDayIndex, anchor: .leading)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.x
        } action: { _, newContentOffset in
            handleContentOffsetChange(newContentOffset)
        }
        .onScrollPhaseChange { _, newPhase, context in
            handleScrollPhaseChange(
                newPhase,
                contentOffset: context.geometry.contentOffset.x
            )
        }
        .onAppear {
            anchorDate = calendar.startOfDay(for: adjustedDate)
            haptics.prepare(.selectionStep)
            recenter()
        }
        .onChange(of: adjustedDate) { _, newDate in
            synchronizeExternalDateChange(newDate)
        }
        .frame(maxWidth: .infinity, maxHeight: lineHeight)
        .accessibilityLabel("调整日期")
    }
}

private extension CapsuleRollerView {
    var tickStride: CGFloat {
        max(lineWidth + lineSpacing, 1)
    }

    var dayStride: CGFloat {
        CGFloat(scale.ticksPerDay) * tickStride
    }

    var centerContentOffset: CGFloat {
        CGFloat(centerDayIndex) * dayStride
    }

    var recenteringTolerance: CGFloat {
        max(tickStride * 0.1, 0.5)
    }

    func handleScrollPhaseChange(_ newPhase: ScrollPhase, contentOffset: CGFloat) {
        currentContentOffset = contentOffset
        scrollPhase = newPhase

        switch newPhase {
        case .tracking, .interacting, .decelerating:
            beginScrubbingIfNeeded()
        case .idle:
            guard !isRecentering else {
                return
            }

            finishScrubbing()
        case .animating:
            break
        }
    }

    func handleContentOffsetChange(_ contentOffset: CGFloat) {
        currentContentOffset = contentOffset

        if isRecentering {
            guard abs(contentOffset - centerContentOffset) <= recenteringTolerance else {
                return
            }

            completeRecentering()
            return
        }

        guard scrollPhase.isScrolling else {
            return
        }

        beginScrubbingIfNeeded()
        apply(dayProgress: dayProgress(for: contentOffset))
    }

    func dayProgress(for contentOffset: CGFloat) -> Double {
        scale.dayProgress(
            contentOffsetDelta: Double(contentOffset - centerContentOffset),
            tickStride: Double(tickStride)
        )
    }

    func beginScrubbingIfNeeded() {
        guard !isRecentering, !isScrubbing else {
            return
        }

        anchorDate = calendar.startOfDay(for: adjustedDate)
        lastAppliedDayOffset = 0
        isScrubbing = true
        scrubState?.begin()
    }

    func apply(dayProgress: Double) {
        let components = scale.split(dayProgress: dayProgress)
        scrubState?.update(residualDayOffset: components.residualDayOffset)

        guard components.dayOffset != lastAppliedDayOffset,
              let targetDate = calendar.date(
                byAdding: .day,
                value: components.dayOffset,
                to: anchorDate
              ) else {
            return
        }

        lastAppliedDayOffset = components.dayOffset
        publish(targetDate)
        haptics.play(.selectionStep)
    }

    func finishScrubbing() {
        guard isScrubbing else {
            recenter()
            return
        }

        let finalDayOffset = scale.split(
            dayProgress: dayProgress(for: currentContentOffset)
        ).dayOffset
        scrubState?.update(residualDayOffset: 0)

        if finalDayOffset != lastAppliedDayOffset,
           let targetDate = calendar.date(
               byAdding: .day,
               value: finalDayOffset,
               to: anchorDate
           ) {
            lastAppliedDayOffset = finalDayOffset
            publish(targetDate)
            haptics.play(.selectionStep)
        }

        anchorDate = calendar.startOfDay(for: adjustedDate)
        lastAppliedDayOffset = 0
        isScrubbing = false
        recenter()
    }

    func publish(_ date: Date) {
        let normalizedDate = calendar.startOfDay(for: date)

        guard !calendar.isDate(normalizedDate, inSameDayAs: adjustedDate) else {
            return
        }

        internallyAppliedDate = normalizedDate
        withAnimation {
            adjustedDate = normalizedDate
        }
    }

    func synchronizeExternalDateChange(_ date: Date) {
        let normalizedDate = calendar.startOfDay(for: date)

        if let internallyAppliedDate,
           calendar.isDate(normalizedDate, inSameDayAs: internallyAppliedDate) {
            self.internallyAppliedDate = nil
            return
        }

        internallyAppliedDate = nil
        anchorDate = normalizedDate
        lastAppliedDayOffset = 0
        isScrubbing = false
        scrubState?.end()
        recenter()
    }

    func recenter() {
        isRecentering = true

        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            scrollDayIndex = centerDayIndex
        }

        if abs(currentContentOffset - centerContentOffset) <= recenteringTolerance {
            completeRecentering()
        }
    }

    func completeRecentering() {
        isRecentering = false
        scrubState?.end()
    }
}

#Preview {
    @Previewable @State var date = Date()

    VStack {
        Text(date.formatted(date: .abbreviated, time: .omitted))

        CapsuleRollerView(
            adjustedDate: $date,
            ticksPerDay: 4,
            lineSpacing: 5,
            lineHeight: 60
        )
    }
}
