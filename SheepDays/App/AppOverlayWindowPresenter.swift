//
//  AppOverlayWindowPresenter.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/5/16.
//

import Combine
import SwiftUI
import SwiftData
import UIKit

struct AppOverlayWindowPresenter: UIViewRepresentable {
    let coordinator: AppOverlayCoordinator
    let haptics: HapticClient
    let modelContainer: ModelContainer

    init(
        coordinator: AppOverlayCoordinator,
        haptics: HapticClient,
        modelContainer: ModelContainer = ModelContainerProvider.shared
    ) {
        self.coordinator = coordinator
        self.haptics = haptics
        self.modelContainer = modelContainer
    }

    func makeCoordinator() -> WindowCoordinator {
        WindowCoordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.update(parent: self, sourceView: uiView)
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: WindowCoordinator) {
        coordinator.teardown()
    }

    final class WindowCoordinator {
        private var window: AppOverlayWindow?
        private var hostingController: UIHostingController<AnyView>?
        private var presentationCancellable: AnyCancellable?
        private var isWaitingForWindow = false

        func update(parent: AppOverlayWindowPresenter, sourceView: UIView) {
            guard let windowScene = sourceView.window?.windowScene else {
                guard !isWaitingForWindow else {
                    return
                }

                isWaitingForWindow = true
                DispatchQueue.main.async { [weak self, weak sourceView] in
                    guard let self, let sourceView else {
                        return
                    }

                    self.isWaitingForWindow = false
                    guard sourceView.window?.windowScene != nil else {
                        return
                    }

                    self.update(parent: parent, sourceView: sourceView)
                }
                return
            }

            isWaitingForWindow = false

            if window?.windowScene === windowScene {
                window?.overlayCoordinator = parent.coordinator
                return
            }

            teardown()

            let overlayWindow = AppOverlayWindow(windowScene: windowScene)
            overlayWindow.windowLevel = .normal + 1
            overlayWindow.backgroundColor = .clear
            overlayWindow.overlayCoordinator = parent.coordinator

            let rootView = AppOverlayHost(coordinator: parent.coordinator)
                .environment(\.appOverlayCoordinator, parent.coordinator)
                .environment(\.haptics, parent.haptics)
                .modelContainer(parent.modelContainer)

            let hostingController = UIHostingController(rootView: AnyView(rootView))
            hostingController.view.backgroundColor = .clear

            overlayWindow.rootViewController = hostingController

            self.window = overlayWindow
            self.hostingController = hostingController
            observePresentationVisibility(
                coordinator: parent.coordinator,
                window: overlayWindow,
                hostingController: hostingController
            )
        }

        func teardown() {
            presentationCancellable?.cancel()
            presentationCancellable = nil
            window?.isHidden = true
            window?.rootViewController = nil
            window = nil
            hostingController = nil
        }

        private func observePresentationVisibility(
            coordinator: AppOverlayCoordinator,
            window: AppOverlayWindow,
            hostingController: UIHostingController<AnyView>
        ) {
            updateVisibility(
                isPresenting: coordinator.isPresenting,
                window: window,
                hostingController: hostingController
            )

            presentationCancellable = coordinator.$currentPresentation.sink { [weak self, weak window, weak hostingController] presentation in
                guard let self, let window, let hostingController else {
                    return
                }

                self.updateVisibility(
                    isPresenting: presentation != nil,
                    window: window,
                    hostingController: hostingController
                )
            }
        }

        private func updateVisibility(
            isPresenting: Bool,
            window: AppOverlayWindow,
            hostingController: UIHostingController<AnyView>
        ) {
            window.isHidden = !isPresenting
            window.accessibilityElementsHidden = !isPresenting
            hostingController.view.accessibilityElementsHidden = !isPresenting
        }
    }
}

final class AppOverlayWindow: UIWindow {
    weak var overlayCoordinator: AppOverlayCoordinator?

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard overlayCoordinator?.isPresenting == true else {
            return false
        }

        return super.point(inside: point, with: event)
    }
}
