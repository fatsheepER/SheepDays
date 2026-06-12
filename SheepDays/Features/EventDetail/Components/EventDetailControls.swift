//
//  EventDetailControls.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/6/12.
//

import SwiftUI

struct EventDetailControls: View {
    let onClose: () -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button {
                onClose()
            } label: {
                SDSheetActionButton(iconSystemName: "arrow.left", title: "返回", placement: .left, appearance: .secondary)
            }
            .buttonStyle(.plain)

            Menu {
                Button {
                    onArchive()
                } label: {
                    Label("归档", systemImage: "tray")
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("删除", systemImage: "trash")
                }
            } label: {
                SDSheetActionButton(iconSystemName: "tray", title: "管理", placement: .right, appearance: .destructive)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    EventDetailControls(
        onClose: {},
        onArchive: {},
        onDelete: {}
    )
    .padding()
    .background(Color(.secondarySystemBackground))
}
