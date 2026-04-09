//
//  NotebookSummaryCard.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/9.
//

import SwiftUI

struct NotebookSummaryCard: View {
    let summary: NotebookSummary
    let onEdit: () -> Void
    let onTap: () -> Void

    private var tintColor: Color {
        guard let hex = summary.notebook.colorHex,
              let color = Color(hex: hex) else {
            return .accentColor
        }

        return color
    }

    private var iconSystemName: String {
        summary.notebook.iconSystemName ?? "book.closed"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // title
            HStack(spacing: 10) {
                SDNotebookBadge(notebook: summary.notebook)
                
                Text("\(summary.activeEventCount)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(tintColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .foregroundStyle(tintColor.opacity(0.15))
                    )

                Spacer()

                // Change to "pencil" when in edit mode
                Button(action: onEdit) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(.tertiaryLabel))
                        .padding(10)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .foregroundStyle(Color(.secondarySystemFill))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 5)

            VStack(alignment: .leading, spacing: 10) {
                // empty indicator
                if summary.previewEvents.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "0.circle")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundStyle(summary.notebook.tintColor)
                            .frame(width: 40)

                        Text("无事件")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color(.secondaryLabel))
                            .lineLimit(1)

                        Spacer(minLength: 8)
                    }
                } else {
                    ForEach(summary.previewEvents) { event in
                        NotebookPreviewEventRow(event: event)
                    }

                    // more indicator
                    if summary.remainingEventCount > 0 {
                        HStack(spacing: 5) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundStyle(summary.notebook.tintColor)
                                .frame(width: 40)

                            Text("\(summary.remainingEventCount) more")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Color(.secondaryLabel))
                                .lineLimit(1)

                            Spacer(minLength: 8)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemGroupedBackground))
        )
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onTapGesture(perform: onTap)
    }
}

private struct NotebookPreviewEventRow: View {
    let event: Event

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: event.iconSystemName ?? "house")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(event.tintColor)
                .frame(width: 40)

            Text(event.title)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color(.secondaryLabel))
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(relativeDayText)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

private extension NotebookPreviewEventRow {
    var relativeDayText: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let target = calendar.startOfDay(for: event.targetDate)
        let offset = calendar.dateComponents([.day], from: today, to: target).day ?? 0

        switch offset {
        case 0:
            return "Today"
        case 1:
            return "Tomorrow"
        case -1:
            return "Yesterday"
        case let value where value > 1:
            return "+\(value)d"
        default:
            return "\(offset)d"
        }
    }
}

#Preview {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)

    let notebook = Notebook(
        name: "生活计划",
        colorHex: "FF8A65",
        iconSystemName: "leaf.fill"
    )

    let previewEvents = [
        Event(
            title: "春游",
            targetDate: today,
            allDay: true,
            notebook: notebook
        ),
        Event(
            title: "健身打卡",
            targetDate: calendar.date(byAdding: .day, value: 2, to: today) ?? today,
            allDay: true,
            notebook: notebook
        ),
        Event(
            title: "换季整理房间",
            targetDate: calendar.date(byAdding: .day, value: 7, to: today) ?? today,
            allDay: true,
            notebook: notebook
        )
    ]

    VStack(spacing: 16) {
        NotebookSummaryCard(
            summary: NotebookSummary(
                notebook: notebook,
                activeEventCount: 5,
                previewEvents: previewEvents,
                remainingEventCount: 2
            ),
            onEdit: {},
            onTap: {}
        )

        NotebookSummaryCard(
            summary: NotebookSummary(
                notebook: Notebook(
                    name: "空事件本",
                    colorHex: "5C6BC0",
                    iconSystemName: "briefcase.fill"
                ),
                activeEventCount: 0,
                previewEvents: [],
                remainingEventCount: 0
            ),
            onEdit: {},
            onTap: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
