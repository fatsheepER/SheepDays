//
//  SDBadge.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import SwiftUI

struct SDIncreBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .contentTransition(.numericText())
            .foregroundStyle(.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                ZStack {
                    Capsule()
                        .foregroundStyle(Color(.systemGroupedBackground))
                    Capsule()
                        .fill(.accent.opacity(0.2))
                }
                
            )
    }
}

#Preview {
    SDIncreBadge(text: "+3")
        .padding()
}
