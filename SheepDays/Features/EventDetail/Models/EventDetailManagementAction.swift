//
//  EventDetailManagementAction.swift
//  SheepDays
//
//  Created by Codex on 2026/6/12.
//

import Foundation

enum EventDetailManagementAction: String, Identifiable {
    case archive
    case delete

    var id: String { rawValue }

    var title: String {
        switch self {
        case .archive:
            return "归档事件"
        case .delete:
            return "删除事件"
        }
    }

    var message: String {
        switch self {
        case .archive:
            return "归档后，这个事件会从当前列表中隐藏。"
        case .delete:
            return "删除后无法恢复。"
        }
    }

    var confirmButtonTitle: String {
        switch self {
        case .archive:
            return "确认归档"
        case .delete:
            return "确认删除"
        }
    }
}
