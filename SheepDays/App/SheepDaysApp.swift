//
//  SheepDaysApp.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import SwiftUI
import SwiftData

@main
struct SheepDaysApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(ModelContainerProvider.shared)
    }
}
