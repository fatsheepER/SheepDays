//
//  HomeDateScrubState.swift
//  SheepDays
//

import Foundation
import Observation

struct HomeDateScrubSnapshot: Equatable, Sendable {
    let isActive: Bool
    let residualDayOffset: Double

    static let idle = HomeDateScrubSnapshot(
        isActive: false,
        residualDayOffset: 0
    )

    static func active(residualDayOffset: Double) -> HomeDateScrubSnapshot {
        HomeDateScrubSnapshot(
            isActive: true,
            residualDayOffset: residualDayOffset
        )
    }
}

@Observable
final class HomeDateScrubState {
    private(set) var snapshot: HomeDateScrubSnapshot = .idle

    func begin() {
        update(residualDayOffset: 0)
    }

    func update(residualDayOffset: Double) {
        let newSnapshot = HomeDateScrubSnapshot.active(
            residualDayOffset: residualDayOffset
        )

        guard snapshot != newSnapshot else {
            return
        }

        snapshot = newSnapshot
    }

    func end() {
        guard snapshot != .idle else {
            return
        }

        snapshot = .idle
    }
}
