//
//  HapticClient.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/21.
//

import Foundation
import UIKit

enum HapticEvent {
    case openDetailTap
    case jumpToDateDoubleTap
    case selectionStep
    case success
    case warning
    case error
    case destructiveConfirm
}

struct HapticClient {
    private let playHandler: (HapticEvent) -> Void
    private let prepareHandler: (HapticEvent) -> Void

    init(
        play: @escaping (HapticEvent) -> Void,
        prepare: @escaping (HapticEvent) -> Void
    ) {
        self.playHandler = play
        self.prepareHandler = prepare
    }

    func play(_ event: HapticEvent) {
        playHandler(event)
    }

    func prepare(_ event: HapticEvent) {
        prepareHandler(event)
    }
}

extension HapticClient {
    static let noop = HapticClient(
        play: { _ in },
        prepare: { _ in }
    )

    static func live(isEnabled: Bool = true) -> HapticClient {
        let performer = LiveHapticPerformer(isEnabled: isEnabled)

        return HapticClient(
            play: { event in
                performer.play(event)
            },
            prepare: { event in
                performer.prepare(event)
            }
        )
    }
}

private final class LiveHapticPerformer {
    private let isEnabled: Bool
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()
    private let doubleTapInterval: TimeInterval = 0.07

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    func play(_ event: HapticEvent) {
        guard isEnabled else {
            return
        }

        runOnMain { [weak self] in
            self?.playOnMain(event)
        }
    }

    func prepare(_ event: HapticEvent) {
        guard isEnabled else {
            return
        }

        runOnMain { [weak self] in
            self?.prepareOnMain(event)
        }
    }
}

private extension LiveHapticPerformer {
    func runOnMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    func playOnMain(_ event: HapticEvent) {
        switch event {
        case .openDetailTap:
            lightImpact.impactOccurred()
            lightImpact.prepare()

        case .jumpToDateDoubleTap:
            lightImpact.impactOccurred()
            lightImpact.prepare()

            DispatchQueue.main.asyncAfter(deadline: .now() + doubleTapInterval) { [weak self] in
                guard let self, self.isEnabled else {
                    return
                }

                self.lightImpact.impactOccurred()
                self.lightImpact.prepare()
            }

        case .selectionStep:
            selection.selectionChanged()
            selection.prepare()

        case .success:
            notification.notificationOccurred(.success)
            notification.prepare()

        case .warning:
            notification.notificationOccurred(.warning)
            notification.prepare()

        case .error:
            notification.notificationOccurred(.error)
            notification.prepare()

        case .destructiveConfirm:
            notification.notificationOccurred(.warning)
            notification.prepare()
        }
    }

    func prepareOnMain(_ event: HapticEvent) {
        switch event {
        case .openDetailTap, .jumpToDateDoubleTap:
            lightImpact.prepare()

        case .selectionStep:
            selection.prepare()

        case .success, .warning, .error, .destructiveConfirm:
            notification.prepare()
        }
    }
}
