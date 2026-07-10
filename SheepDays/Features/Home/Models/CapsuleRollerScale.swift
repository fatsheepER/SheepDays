//
//  CapsuleRollerScale.swift
//  SheepDays
//

import Foundation

struct CapsuleRollerScale: Equatable, Sendable {
    let ticksPerDay: Int

    init(ticksPerDay: Int = 4) {
        self.ticksPerDay = max(ticksPerDay, 1)
    }

    func dayProgress(contentOffsetDelta: Double, tickStride: Double) -> Double {
        guard tickStride > 0 else {
            return 0
        }

        return contentOffsetDelta / (Double(ticksPerDay) * tickStride)
    }

    func split(dayProgress: Double) -> (dayOffset: Int, residualDayOffset: Double) {
        let dayOffset = Int(dayProgress.rounded(.toNearestOrAwayFromZero))
        return (dayOffset, dayProgress - Double(dayOffset))
    }
}
