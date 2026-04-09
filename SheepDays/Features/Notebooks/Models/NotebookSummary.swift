//
//  NotebookSummary.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/9.
//

import SwiftUI

struct NotebookSummary: Identifiable {
    let notebook: Notebook
    let activeEventCount: Int
    let previewEvents: [Event]
    let remainingEventCount: Int

    var id: UUID {
        notebook.id
    }
}
