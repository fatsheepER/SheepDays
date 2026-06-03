//
//  HomeDateView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/2.
//

import SwiftUI

struct HomeDateView: View {
    private let content: HomeDateDisplayContent

    init(referenceDate: Date, today: Date = .now, calendar: Calendar = .current) {
        self.content = HomeDateDisplayContent(
            referenceDate: referenceDate,
            today: today,
            calendar: calendar
        )
    }

    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            // day
            Text(content.dayText)
                .contentTransition(.numericText())
                .font(.system(size:75, weight: .bold, design: .serif))
                .foregroundStyle(.accent)
                .modifier(DayTextLifeEffect())
                .frame(width: 100)

            VStack(alignment: .leading, spacing: 5) {
                // year - only when not this year
                if let yearText = content.yearText {
                    Text(yearText)
                        .contentTransition(.numericText())
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 5) {
                    // month
                    Text(content.monthText)
                        .contentTransition(.numericText())
                        .font(.system(size: 35, weight: .semibold, design: .serif))
                }
                

                HStack(spacing: 10) {
                    // weekday
                    WeekdayIndicatorView(
                        text: content.weekdayAbbreviationText,
                        date: content.referenceDate
                    )
                    
                    // incre badge
                    if content.dayOffsetFromToday != 0 {
                        SDIncreBadge(text: content.badgeText)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)

        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DayTextLifeEffect: ViewModifier {
    @State private var floatOffset = CGSize.zero
    @State private var motionTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .shadow(color: .accent.opacity(0.38), radius: 10, x: 0, y: 3)
            .shadow(color: .accent.opacity(0.22), radius: 22, x: 0, y: 7)
            .offset(floatOffset)
            .onAppear {
                startMotion()
            }
            .onDisappear {
                motionTask?.cancel()
                motionTask = nil
            }
    }

    private func startMotion() {
        guard motionTask == nil else {
            return
        }

        motionTask = Task { @MainActor in
            while !Task.isCancelled {
                let duration = Double.random(in: 1.4...2.2)
                let nextOffset = CGSize(
                    width: CGFloat.random(in: -1.8...1.8),
                    height: CGFloat.random(in: -1.4...1.4)
                )

                withAnimation(.smooth(duration: duration)) {
                    floatOffset = nextOffset
                }

                try? await Task.sleep(for: .milliseconds(Int(duration * 1_000)))
            }
        }
    }
}

private enum WeekdayRollDirection {
    case forward
    case backward

    var insertionEdge: Edge {
        switch self {
        case .forward:
            return .bottom
        case .backward:
            return .top
        }
    }

    var removalEdge: Edge {
        switch self {
        case .forward:
            return .top
        case .backward:
            return .bottom
        }
    }

    var scrubRotationStep: Double {
        switch self {
        case .forward:
            return -180
        case .backward:
            return 180
        }
    }
}

private struct WeekdayIndicatorView: View {
    let text: String
    let date: Date

    @State private var displayedText: String
    @State private var pendingText: String
    @State private var pendingDate: Date
    @State private var isScrubbing = false
    @State private var direction: WeekdayRollDirection = .forward
    @State private var scrubRotation = 0.0
    @State private var settleTask: Task<Void, Never>?

    init(text: String, date: Date) {
        self.text = text
        self.date = date
        _displayedText = State(initialValue: text)
        _pendingText = State(initialValue: text)
        _pendingDate = State(initialValue: date)
    }

    var body: some View {
        ZStack {
            if isScrubbing {
                scrubContent
                    .id("scrub-\(pendingDate.timeIntervalSinceReferenceDate)")
                    .transition(rollTransition)
            } else {
                weekdayText(displayedText)
                    .id(displayedText)
                    .transition(rollTransition)
            }
        }
        .frame(width: 68, height: 35)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .foregroundStyle(Color(.secondarySystemGroupedBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(.separator), lineWidth: 2)
        }
        .onChange(of: date) { oldDate, newDate in
            beginTransition(from: oldDate, to: newDate, text: text)
        }
        .onDisappear {
            settleTask?.cancel()
        }
    }

    private var scrubContent: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { _ in
//                Capsule()
//                    .fill(.secondary.opacity(0.36))
//                    .frame(width: 9, height: 4)
                
                RoundedRectangle(cornerRadius: 100, style: .continuous)
                    .fill(.secondary.opacity(0.5))
                    .frame(width: 4, height: 20)
                    .frame(width: 15)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .blur(radius: 0.7)
        .opacity(0.8)
        .rotation3DEffect(
            .degrees(scrubRotation),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.65
        )
    }

    private var rollTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: direction.insertionEdge).combined(with: .opacity),
            removal: .move(edge: direction.removalEdge).combined(with: .opacity)
        )
    }

    private func weekdayText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 21, weight: .semibold, design: .rounded))
            .tracking(3)
            .foregroundStyle(.secondary)
    }

    private func beginTransition(from oldDate: Date, to newDate: Date, text newText: String) {
        let newDirection: WeekdayRollDirection = newDate >= oldDate ? .forward : .backward

        direction = newDirection
        pendingText = newText
        pendingDate = newDate
        settleTask?.cancel()

        withAnimation(.easeInOut(duration: 0.11)) {
            isScrubbing = true
            scrubRotation += newDirection.scrubRotationStep
        }

        settleTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            guard !Task.isCancelled else {
                return
            }

            withAnimation(.smooth(duration: 0.26)) {
                displayedText = pendingText
                isScrubbing = false
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        HomeDateView(referenceDate: .now)
        HomeDateView(referenceDate: Calendar.current.date(byAdding: .day, value: 4, to: .now) ?? .now)
        HomeDateView(referenceDate: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now)
        HomeDateView(referenceDate: Calendar.current.date(byAdding: .year, value: 2, to: .now) ?? .now)
    }
    .padding()
}
