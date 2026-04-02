//
//  SDSheetTitleView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/2.
//

import SwiftUI

struct SDSheetTitleView: View {
    let iconSystemName: String?
    let title: String
    
    init(iconSystemName: String? = nil, title: String) {
        self.iconSystemName = iconSystemName
        self.title = title
    }
    
    var body: some View {
        HStack(spacing: 5) {
            if let systemName = iconSystemName {
                Image(systemName: systemName)
            }
            
            Text(title)
        }
        .font(.system(size: 20, weight: .semibold, design: .rounded))
        .foregroundStyle(Color(.secondaryLabel))
        .frame(height: 25)
    }
}

#Preview {
    VStack {
        SDSheetTitleView(iconSystemName: "plus", title: "创建新事件")
        
        SDSheetTitleView(iconSystemName: "eye", title: "聚焦")
        
        SDSheetTitleView(title: "没有图标的标题")
    }
}
