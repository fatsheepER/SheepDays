//
//  SDHeaderActionButton.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/24.
//

import SwiftUI

struct SDHeaderActionButton: View {
    let iconSystemName: String
    let foregroundColor: Color
    let backgroundColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: iconSystemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(foregroundColor)
                .padding(10)
                .background(
                    Circle()
                        .fill(backgroundColor)
                )
        }
        .buttonStyle(.plain)
    }
    
    init(iconSystemName: String, foregroundColor: Color, backgroundColor: Color, action: @escaping () -> Void) {
        self.iconSystemName = iconSystemName
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.action = action
    }
    
    init(iconSystemName: String, action: @escaping () -> Void) {
        self.iconSystemName = iconSystemName
        self.foregroundColor = Color(.secondaryLabel)
        self.backgroundColor = Color(.secondarySystemBackground)
        self.action = action
    }
    
    init(action: @escaping () -> Void) {
        self.iconSystemName = "xmark"
        self.foregroundColor = Color(.secondaryLabel)
        self.backgroundColor = Color(.secondarySystemBackground)
        self.action = action
    }
}

#Preview {
    VStack(spacing: 15) {
        SDHeaderActionButton() {}
        
        SDHeaderActionButton(iconSystemName: "checkmark") {}
        
        SDHeaderActionButton(iconSystemName: "tag", foregroundColor: .accent, backgroundColor: .accentColorSecondary) {
            
        }
    }
    .padding()
}
