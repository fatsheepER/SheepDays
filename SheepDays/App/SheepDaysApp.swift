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
    private let appEnvironment = AppEnvironment.live

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.haptics, appEnvironment.haptics)
        }
        .modelContainer(ModelContainerProvider.shared)
    }
}
