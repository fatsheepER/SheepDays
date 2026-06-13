//
//  NotebookDetailView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/6/13.
//

import SwiftUI

struct NotebookDetailView: View {
    let notebook: Notebook
    let onBack: () -> Void
    var onEdit: () -> Void = {}

    var body: some View {
        VStack(spacing: 10) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 15) {
                    NotebookDetailHeader(
                        notebook: notebook,
                        futureEventCount: futureEventCount,
                        accentColor: accentColor
                    )

                    NotebookDetailStats(
                        totalCount: activeEvents.count,
                        todayCount: todayEventCount,
                        pastCount: pastEventCount,
                        accentColor: accentColor
                    )

                    if let note = notebook.note, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color(.secondaryLabel))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(15)
                            .background(
                                SDRoundedBackground(
                                    topLeading: 20,
                                    topTrailing: 20,
                                    bottomLeading: 20,
                                    bottomTrailing: 10,
                                    color: Color(.tertiarySystemGroupedBackground)
                                )
                            )
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 20)
            }
            .background(
                SDRoundedBackground(
                    topLeading: 30,
                    topTrailing: 30,
                    bottomLeading: 15,
                    bottomTrailing: 15,
                    color: Color(.secondarySystemGroupedBackground)
                )
            )
            .clipShape(
                SDRoundedCornersShape(
                    topLeading: 30,
                    topTrailing: 30,
                    bottomLeading: 15,
                    bottomTrailing: 15,
                    style: .continuous
                )
            )

            controls
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemGroupedBackground))
    }
}

private extension NotebookDetailView {
    var accentColor: Color {
        notebook.tintColor
    }

    var activeEvents: [Event] {
        notebook.events.filter { event in
            !event.isArchived && event.notebook?.id == notebook.id
        }
    }

    var futureEventCount: Int {
        activeEvents.filter { normalizedDay(for: $0.targetDate) > today }.count
    }

    var todayEventCount: Int {
        activeEvents.filter { normalizedDay(for: $0.targetDate) == today }.count
    }

    var pastEventCount: Int {
        activeEvents.filter { normalizedDay(for: $0.targetDate) < today }.count
    }

    var today: Date {
        Calendar.current.startOfDay(for: .now)
    }

    var controls: some View {
        HStack {
            Button(action: onBack) {
                SDSheetActionButton(
                    iconSystemName: "arrow.left",
                    title: "返回",
                    placement: .left,
                    appearance: .plain
                )
            }
            .buttonStyle(.plain)

            Button(action: onEdit) {
                SDSheetActionButton(
                    iconSystemName: "pencil",
                    title: "编辑",
                    placement: .right,
                    backgroundColor: accentColor.opacity(0.2),
                    titleForegroundColor: accentColor
                )
            }
            .buttonStyle(.plain)
        }
    }

    func normalizedDay(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
}

private struct NotebookDetailHeader: View {
    let notebook: Notebook
    let futureEventCount: Int
    let accentColor: Color

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: notebook.iconSystemName ?? "book.closed")
                    .font(.system(size: 38, weight: .medium, design: .rounded))
                    .frame(width: 48, height: 44)
                    .accessibilityHidden(true)

                Text(notebook.name)
                    .font(.system(size: 36, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(accentColor)
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(futureEventCount)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText())

                Text("个未来的事件")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(accentColor)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(10)
        }
        .padding(.vertical, 4)
    }
}

private struct NotebookDetailStats: View {
    let totalCount: Int
    let todayCount: Int
    let pastCount: Int
    let accentColor: Color

    var body: some View {
        HStack(spacing: 10) {
            NotebookDetailStatBadge(title: "全部事件", count: totalCount, accentColor: accentColor)
            NotebookDetailStatBadge(title: "今天", count: todayCount, accentColor: accentColor)
            NotebookDetailStatBadge(title: "已经历", count: pastCount, accentColor: accentColor)
        }
    }
}

private struct NotebookDetailStatBadge: View {
    let title: String
    let count: Int
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(.secondaryLabel))

            Text("\(count)")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(accentColor)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            SDRoundedBackground(
                topLeading: 18,
                topTrailing: 18,
                bottomLeading: 18,
                bottomTrailing: 8,
                color: accentColor.opacity(0.2)
            )
        )
    }
}

#Preview {
    let notebook = Notebook(
        name: "比赛",
        colorHex: "00AEB3",
        iconSystemName: "sportscourt"
    )

    NotebookDetailView(notebook: notebook, onBack: {})
        .padding()
        .background(Color(.systemGroupedBackground))
}
