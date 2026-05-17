//
//  AppOverlayCoordinator.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/5/16.
//

import Combine
import SwiftUI

enum AppOverlayPresentation: Identifiable {
    case symbolPicker(presentation: SymbolPickerPresentation, onDismiss: () -> Void)
    case tagList(presentation: TagListPresentation, onDismiss: () -> Void)

    var id: UUID {
        switch self {
        case .symbolPicker(let presentation, _):
            return presentation.id
        case .tagList(let presentation, _):
            return presentation.id
        }
    }

    func performDismiss() {
        switch self {
        case .symbolPicker(_, let onDismiss),
             .tagList(_, let onDismiss):
            onDismiss()
        }
    }
}

final class AppOverlayCoordinator: ObservableObject {
    @Published private(set) var currentPresentation: AppOverlayPresentation?

    var isPresenting: Bool {
        currentPresentation != nil
    }

    func present(_ presentation: AppOverlayPresentation) {
        currentPresentation = presentation
    }

    func dismissCurrent() {
        let presentation = currentPresentation
        currentPresentation = nil
        presentation?.performDismiss()
    }

    func dismiss(presentationID: UUID) {
        guard currentPresentation?.id == presentationID else {
            return
        }

        dismissCurrent()
    }
}

private struct AppOverlayCoordinatorEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppOverlayCoordinator()
}

extension EnvironmentValues {
    var appOverlayCoordinator: AppOverlayCoordinator {
        get { self[AppOverlayCoordinatorEnvironmentKey.self] }
        set { self[AppOverlayCoordinatorEnvironmentKey.self] = newValue }
    }
}
