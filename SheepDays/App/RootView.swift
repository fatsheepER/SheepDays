//
//  ContentView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import SwiftUI
import SwiftData

struct RootView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    RootView()
        .modelContainer(ModelContainerProvider.makePreviewContainer())
}
