//
//  HomePreviewSupport.swift
//  SheepDays
//
//  Created by Codex on 2026/6/12.
//

import Foundation
import SwiftData

enum HomePreviewSupport {
    static let notebookDefinitions: [(name: String, colorHex: String, iconSystemName: String)] = [
        ("Preview Inbox", "#FFB347", "tray.full.fill"),
        ("Preview Life", "#7EC8E3", "leaf.fill"),
        ("Preview Work", "#FF7A7A", "briefcase.fill")
    ]

    static let tagNames = [
        "Preview Health",
        "Preview Family",
        "Preview Travel",
        "Preview Launch"
    ]

    static let eventTitlePrefixes = [
        "Preview Event ",
        "Preview Memorial "
    ]

    static let eventDayOffsets: [Int] = [
        0, 1, 2, 3, 5, 7, 10, 14, 21, 30,
        45, 60, 75, 90, 105, 120, 135, 150, 165, 180
    ]

    private static let memorialDefinitions: [PreviewMemorialDefinition] = [
        PreviewMemorialDefinition(
            title: "Preview Memorial Graduation",
            note: "Past memorial sample for the memorial timeline.",
            dayOffset: -120,
            iconSystemName: "graduationcap.fill",
            notebookIndex: 1,
            tagIndices: [1, 3],
            checklistItems: [
                ("整理照片", true),
                ("补一段回忆备注", false)
            ]
        ),
        PreviewMemorialDefinition(
            title: "Preview Memorial First Trip",
            note: "Another expired memorial event.",
            dayOffset: -28,
            iconSystemName: "airplane.departure",
            notebookIndex: 1,
            tagIndices: [2],
            checklistItems: [
                ("确认相册封面", true)
            ]
        ),
        PreviewMemorialDefinition(
            title: "Preview Memorial Today",
            note: "Today belongs to both the upcoming and memorial scopes.",
            dayOffset: 0,
            iconSystemName: "sparkles",
            notebookIndex: 0,
            tagIndices: [1],
            checklistItems: [
                ("写一条纪念日记录", false),
                ("选一个当天图标", true)
            ]
        ),
        PreviewMemorialDefinition(
            title: "Preview Memorial Anniversary",
            note: "Upcoming memorial sample for home scope testing.",
            dayOffset: 18,
            iconSystemName: "heart.fill",
            notebookIndex: 1,
            tagIndices: [1],
            checklistItems: [
                ("准备礼物", false),
                ("预约晚餐", false),
                ("写卡片", true)
            ]
        ),
        PreviewMemorialDefinition(
            title: "Preview Memorial Reunion",
            note: "Future memorial that should remain on the upcoming page.",
            dayOffset: 96,
            iconSystemName: "person.2.fill",
            notebookIndex: 0,
            tagIndices: [1, 2],
            checklistItems: []
        )
    ]

    static func insertPreviewData(in context: ModelContext) throws {
        let notebooks = notebookDefinitions.map { definition in
            Notebook(
                name: definition.name,
                colorHex: definition.colorHex,
                iconSystemName: definition.iconSystemName
            )
        }
        let tags = tagNames.map(Tag.init(name:))

        notebooks.forEach(context.insert)
        tags.forEach(context.insert)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let icons = [
            "calendar",
            "party.popper.fill",
            "airplane",
            "gift.fill",
            "star.fill"
        ]

        for (index, dayOffset) in eventDayOffsets.enumerated() {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                continue
            }

            let notebook = notebooks[index % notebooks.count]
            let event = Event(
                title: "Preview Event \(index + 1)",
                note: "Temporary sample data for home layout testing.",
                targetDate: targetDate,
                allDay: true,
                iconSystemName: icons[index % icons.count],
                importanceLevel: index % 3,
                showOnHome: true,
                pinToTop: index == 0,
                notebook: notebook,
                tags: previewTags(for: index, from: tags)
            )

            context.insert(event)
            insertPreviewChecklistItems(for: event, eventIndex: index, in: context)
        }

        for definition in memorialDefinitions {
            guard let targetDate = calendar.date(byAdding: .day, value: definition.dayOffset, to: today) else {
                continue
            }

            let event = Event(
                title: definition.title,
                note: definition.note,
                targetDate: targetDate,
                allDay: true,
                isMemorial: true,
                iconSystemName: definition.iconSystemName,
                importanceLevel: abs(definition.dayOffset / 30) % 3,
                showOnHome: true,
                pinToTop: definition.dayOffset == 0,
                notebook: notebooks[definition.notebookIndex % notebooks.count],
                tags: previewTags(at: definition.tagIndices, from: tags)
            )

            context.insert(event)
            insertPreviewChecklistItems(definition.checklistItems, for: event, in: context)
        }

        try context.save()
    }

    static func removePreviewData(in context: ModelContext) throws {
        let events = try context.fetch(FetchDescriptor<Event>())
        let notebooks = try context.fetch(FetchDescriptor<Notebook>())
        let tags = try context.fetch(FetchDescriptor<Tag>())
        let previewNotebookNames = Set(notebookDefinitions.map(\.name))
        let previewTagNames = Set(tagNames)

        for event in events where eventTitlePrefixes.contains(where: event.title.hasPrefix) {
            context.delete(event)
        }

        for notebook in notebooks where previewNotebookNames.contains(notebook.name) {
            context.delete(notebook)
        }

        for tag in tags where previewTagNames.contains(tag.name) {
            context.delete(tag)
        }
    }
}

private extension HomePreviewSupport {
    static func previewTags(for eventIndex: Int, from tags: [Tag]) -> [Tag] {
        switch eventIndex % 5 {
        case 0:
            return previewTags(at: [0, 3], from: tags)
        case 1:
            return previewTags(at: [1], from: tags)
        case 2:
            return previewTags(at: [2], from: tags)
        case 3:
            return []
        default:
            return previewTags(at: [0], from: tags)
        }
    }

    static func previewTags(at indices: [Int], from tags: [Tag]) -> [Tag] {
        indices.compactMap { index in
            guard tags.indices.contains(index) else {
                return nil
            }

            return tags[index]
        }
    }

    static func insertPreviewChecklistItems(for event: Event, eventIndex: Int, in context: ModelContext) {
        switch eventIndex % 6 {
        case 0:
            insertPreviewChecklistItems(
                [
                    ("确认时间", true),
                    ("准备资料", false),
                    ("同步给相关人", false)
                ],
                for: event,
                in: context
            )
        case 2:
            insertPreviewChecklistItems(
                [
                    ("订票", true),
                    ("收拾行李", false)
                ],
                for: event,
                in: context
            )
        case 4:
            insertPreviewChecklistItems(
                [
                    ("写下备忘", false)
                ],
                for: event,
                in: context
            )
        default:
            break
        }
    }

    static func insertPreviewChecklistItems(
        _ items: [(title: String, isCompleted: Bool)],
        for event: Event,
        in context: ModelContext
    ) {
        for (index, item) in items.enumerated() {
            let checklistItem = ChecklistItem(
                title: item.title,
                isCompleted: item.isCompleted,
                sortIndex: index + 1,
                event: event
            )

            context.insert(checklistItem)
            event.checklistItems.append(checklistItem)
        }
    }
}

private struct PreviewMemorialDefinition {
    let title: String
    let note: String
    let dayOffset: Int
    let iconSystemName: String
    let notebookIndex: Int
    let tagIndices: [Int]
    let checklistItems: [(title: String, isCompleted: Bool)]
}
