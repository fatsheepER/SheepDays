//
//  HomeSheetActionCard.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/2.
//

import SwiftUI

struct HomeSheetActionCard: View {
    let title: String
    let systemImage: String
    var action: () -> Void = {}
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Spacer()
                
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .frame(height: 22)
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                
                Spacer()
            }
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 35, style: .continuous)
                    .fill(.quinary)
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HStack(spacing: 10) {
        HomeSheetActionCard(title: "聚焦", systemImage: "eye")
        
        HomeSheetActionCard(title: "创建新事件", systemImage: "plus")
        
        HomeSheetActionCard(title: "事件本", systemImage: "list.bullet")
    }
    .padding(.horizontal, 10)
    
}
