//
//  NotebookDetailEventList.swift
//  SheepDays
//
//  Created by Codex on 2026/7/13.
//

import SwiftUI

struct NotebookDetailEventList: View {
    let notebook: Notebook
    let activeEvents: [Event]
    let archivedEvents: [Event]
    @Binding var isShowingArchivedEvents: Bool
    var onDeleteEvent: (Event) -> Void = { _ in }

    private var today: Date {
        Calendar.current.startOfDay(for: .now)
    }

    var body: some View {
        List {
            if activeEvents.isEmpty {
                NotebookDetailEmptyEventRow()
                    .notebookDetailListRowStyle()
            } else {
                ForEach(activeEvents) { event in
                    NotebookDetailEventRow(
                        event: event,
                        notebook: notebook,
                        today: today,
                        onDelete: { onDeleteEvent(event) }
                    )
                    .notebookDetailListRowStyle()
                }
            }

            if isShowingArchivedEvents, !archivedEvents.isEmpty {
                Section {
                    ForEach(archivedEvents) { event in
                        NotebookDetailEventRow(
                            event: event,
                            notebook: notebook,
                            today: today,
                            onDelete: { onDeleteEvent(event) }
                        )
                        .notebookDetailListRowStyle()
                    }
                } header: {
                    NotebookArchivedEventsSectionHeader()
                }
            }

            if !archivedEvents.isEmpty {
                NotebookArchivedEventsToggleRow(
                    isShowingArchivedEvents: $isShowingArchivedEvents,
                    archivedEventCount: archivedEvents.count
                )
                .notebookDetailListRowStyle()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 10, for: .scrollContent)
        .contentMargins(.bottom, 10, for: .scrollContent)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .animation(.snappy(duration: 0.28, extraBounce: 0), value: isShowingArchivedEvents)
    }
}

private struct NotebookDetailEventRow: View {
    let event: Event
    let notebook: Notebook
    let today: Date
    let onDelete: () -> Void

    var body: some View {
        SDEventItemView(
            item: displayItem,
            visibleStateIndicators: .notebookDetail
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("删除", systemImage: "trash")
            }
        }
    }

    private var displayItem: HomeDisplayItem {
        let dateDisplay = HomeDateDisplayContent(
            referenceDate: event.targetDate,
            today: today
        )

        return HomeDisplayItem(
            id: event.id,
            sourceEventId: event.id,
            title: event.title,
            iconSystemName: event.iconSystemName,
            tintHex: notebook.colorHex,
            badgeText: dateDisplay.badgeText,
            isToday: dateDisplay.dayOffsetFromToday == 0,
            stateIndicators: stateIndicators,
            sortKey: Double(dateDisplay.dayOffsetFromToday),
            groupKey: nil
        )
    }

    private var stateIndicators: Set<HomeDisplayItemStateIndicator> {
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

private struct NotebookArchivedEventsSectionHeader: View {
    var body: some View {
        Label("已归档", systemImage: "tray.full")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color(.tertiaryLabel))
            .textCase(nil)
            .padding(.horizontal, 5)
    }
}

private struct NotebookArchivedEventsToggleRow: View {
    @Binding var isShowingArchivedEvents: Bool
    let archivedEventCount: Int

    var body: some View {
        Button {
            isShowingArchivedEvents.toggle()
        } label: {
            Label(
                isShowingArchivedEvents ? "隐藏已归档事件" : "已归档事件",
                systemImage: isShowingArchivedEvents ? "eye.slash" : "tray"
            )
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color(.tertiaryLabel))
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(archivedEventCount == 0)
        .opacity(archivedEventCount == 0 ? 0.45 : 1)
        .accessibilityValue("\(archivedEventCount) 个事件")
    }
}

private struct NotebookDetailEmptyEventRow: View {
    var body: some View {
        ContentUnavailableView(
            "没有事件",
            systemImage: "calendar.badge.checkmark",
            description: Text("这个事件本中还没有未归档事件。")
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}

private extension View {
    func notebookDetailListRowStyle() -> some View {
        listRowInsets(
            EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15)
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}
