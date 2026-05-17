//
//  AppOverlayHost.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/5/16.
//

import SwiftUI

struct AppOverlayHost: View {
    @ObservedObject var coordinator: AppOverlayCoordinator

    var body: some View {
        ZStack {
            if let presentation = coordinator.currentPresentation {
                overlay(for: presentation)
                    .id(presentation.id)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .allowsHitTesting(coordinator.isPresenting)
    }
}

private extension AppOverlayHost {
    @ViewBuilder
    func overlay(for presentation: AppOverlayPresentation) -> some View {
        switch presentation {
        case .symbolPicker(let symbolPickerPresentation, _):
            SymbolPickerOverlayView(
                isPresented: true,
                title: symbolPickerPresentation.title,
                sections: symbolPickerPresentation.sections,
                selectedSystemName: symbolPickerPresentation.selectedSystemName,
                tintColor: symbolPickerPresentation.tintColor,
                presentationDelay: .zero,
                onSelect: symbolPickerPresentation.onSelect,
                onClose: {
                    coordinator.dismiss(presentationID: presentation.id)
                }
            )

        case .tagList(let tagListPresentation, _):
            TagListOverlayView(
                isPresented: true,
                mode: tagListPresentation.mode,
                presentationDelay: .zero,
                onClose: {
                    coordinator.dismiss(presentationID: presentation.id)
                }
            )
        }
    }
}
