//
//  EventDetailNoteSection.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/6/12.
//

import SwiftUI

struct EventDetailNoteSection: View {
    @Binding var note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            EventDetailSectionTitle(title: "备注", systemImage: "note.text")

            TextEditor(text: $note)
                .textEditorStyle(.plain)
                .frame(minHeight: 80)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                )
        }
    }
}

#Preview {
    @Previewable @State var note = "这一块先放一段预览备注，方便微调 noteSection。"

    EventDetailNoteSection(note: $note)
        .padding()
}
