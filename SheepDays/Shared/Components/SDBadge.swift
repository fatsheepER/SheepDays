//
//  SDBadge.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import SwiftUI

struct SDBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .contentTransition(.numericText())
            .foregroundStyle(.accent)
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(.accentColorSecondary)
            )
    }
}

#Preview {
    SDBadge(text: "+3")
        .padding()
}
