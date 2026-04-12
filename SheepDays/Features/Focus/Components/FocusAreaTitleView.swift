//
//  FocusAreaTitleView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/11.
//

import SwiftUI

struct FocusAreaTitleView: View {
    let iconSystemName: String
    let title: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: iconSystemName)
            Text(title)
        }
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(Color(.tertiaryLabel))
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        FocusAreaTitleView(iconSystemName: "tray.full", title: "来源范围")
        FocusAreaTitleView(iconSystemName: "arrow.up.arrow.down", title: "排序方式")
    }
    .padding()
}
