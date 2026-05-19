//
//  SectionHeaderView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/2.
//

import SwiftUI

struct SectionHeaderView: View {
    let title: String

    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(.tertiaryLabel))

                Spacer(minLength: 0)
            }
            
            Capsule(style: .continuous)
                .frame(height: 1.5)
                .foregroundStyle(Color(.separator))
        }
        
    }
}

#Preview {
    SectionHeaderView(title: "Upcoming")
        .padding()
}
