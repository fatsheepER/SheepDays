//
//  TagListMode.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/5/16.
//

import SwiftUI

enum TagListMode {
    case management
    case selection(selectedTagIDs: Set<UUID>, onSelectionChange: (Set<UUID>) -> Void)

    var initialSelectedTagIDs: Set<UUID> {
        switch self {
        case .management:
            return []
        case .selection(let selectedTagIDs, _):
            return selectedTagIDs
        }
    }
}
