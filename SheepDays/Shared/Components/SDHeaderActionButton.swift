//
//  SDHeaderActionButton.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/24.
//

import SwiftUI

struct SDHeaderActionButton: View {
    let iconSystemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: iconSystemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(.secondaryLabel))
                .padding(10)
                .background(
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SDHeaderActionButton(iconSystemName: "xmark") {}
        .padding()
        .background(Color(.systemBackground))
}
