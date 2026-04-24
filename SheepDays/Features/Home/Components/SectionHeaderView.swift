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
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            
            Divider()
        }
        
    }
}

#Preview {
    SectionHeaderView(title: "Upcoming")
        .padding()
}
