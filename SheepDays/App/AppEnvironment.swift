//
//  AppEnvironment.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import SwiftUI

struct AppEnvironment {
    let haptics: HapticClient

    static let live = AppEnvironment(
        haptics: .live()
    )
}

private struct HapticsEnvironmentKey: EnvironmentKey {
    static let defaultValue = HapticClient.noop
}

extension EnvironmentValues {
    var haptics: HapticClient {
        get { self[HapticsEnvironmentKey.self] }
        set { self[HapticsEnvironmentKey.self] = newValue }
    }
}
