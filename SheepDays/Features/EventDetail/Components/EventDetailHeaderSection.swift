//
//  EventDetailHeaderSection.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/6/12.
//

import SwiftUI

struct EventDetailHeaderSection: View {
    let iconSystemName: String?
    let accentColor: Color
    let remainingDaysText: String
    @Binding var title: String
    let onIconTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Button {
                    onIconTap()
                } label: {
                    Image(systemName: iconSystemName ?? "calendar")
                        .font(.system(size: 40, weight: .medium, design: .rounded))
                        .foregroundStyle(accentColor)
                }
                .buttonStyle(.plain)
                .frame(height: 50)

                Spacer()

                Text(remainingDaysText)
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
            }
            .padding(.horizontal, 5)

            TextField("请输入事件名称", text: $title)
                .textFieldStyle(.plain)
                .font(.system(size: 25, weight: .semibold, design: .rounded))
        }
    }
}

#Preview {
    @Previewable @State var title = "Project Launch"

    EventDetailHeaderSection(
        iconSystemName: "flag.fill",
        accentColor: .orange,
        remainingDaysText: "还有 12 天",
        title: $title,
        onIconTap: {}
    )
    .padding()
}
