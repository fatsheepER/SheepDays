//
//  HomeDateView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/2.
//

import SwiftUI

private extension VerticalAlignment {
    enum HomeDateTextBottomAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[.bottom]
        }
    }

    static let homeDateTextBottom = VerticalAlignment(HomeDateTextBottomAlignment.self)
}

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
        HStack(alignment: .homeDateTextBottom, spacing: 15) {
            // day
            Text(content.dayText)
                .contentTransition(.numericText())
                .font(.system(size: 80, weight: .bold, design: .serif))
                .foregroundStyle(.accent)
                .alignmentGuide(.homeDateTextBottom) { context in
                    context[.lastTextBaseline]
                }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) {
                    // month
                    Text(content.monthText)
                        .contentTransition(.numericText())

                    // year - only when not this year
                    if let yearText = content.yearText {
                        Text(yearText)
                            .contentTransition(.numericText())
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.system(size: 35, weight: .semibold, design: .serif))

                HStack(spacing: 10) {
                    // incre badge
                    if content.dayOffsetFromToday != 0 {
                        SDIncreBadge(text: content.badgeText)
                            .padding(.leading, 5)
                            .transition(.scale.combined(with: .opacity))
                    }

                    Text(content.dayOfWeekText)
                        .contentTransition(.opacity)
                        .font(.system(size: 25, weight: .medium, design: .serif))
                        .alignmentGuide(.homeDateTextBottom) { context in
                            context[.lastTextBaseline]
                        }
                }
            }
            .fixedSize(horizontal: false, vertical: true)

        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
