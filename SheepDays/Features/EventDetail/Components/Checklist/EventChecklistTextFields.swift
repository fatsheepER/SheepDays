//
//  EventChecklistTextFields.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/6/12.
//

import SwiftUI
import UIKit

struct ChecklistCreateTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let isFocused: Bool
    let onSubmit: () -> Void
    let onBeginEditing: () -> Void
    let onEndEditing: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.font = .systemFont(ofSize: 18, weight: .medium)
        textField.textColor = .secondaryLabel
        textField.placeholder = placeholder
        textField.returnKeyType = .done
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange(_:)),
            for: .editingChanged
        )
        textField.delegate = context.coordinator
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self

        if uiView.text != text {
            uiView.text = text
        }

        uiView.placeholder = placeholder

        if isFocused, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: ChecklistCreateTextField

        init(parent: ChecklistCreateTextField) {
            self.parent = parent
        }

        @objc func textDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onSubmit()

            if textField.text != parent.text {
                textField.text = parent.text
            }

            return false
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onBeginEditing()
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.onEndEditing()
        }
    }
}

struct ChecklistTitleTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let isFocused: Bool
    let onEmptyBackspace: () -> Void
    let onBeginEditing: () -> Void
    let onEndEditing: () -> Void

    func makeUIView(context: Context) -> EmptyBackspaceTextField {
        let textField = EmptyBackspaceTextField()
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.font = .systemFont(ofSize: 18, weight: .medium)
        textField.textColor = .secondaryLabel
        textField.placeholder = placeholder
        textField.returnKeyType = .done
        textField.onEmptyBackspace = context.coordinator.handleEmptyBackspace
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange(_:)),
            for: .editingChanged
        )
        textField.delegate = context.coordinator
        return textField
    }

    func updateUIView(_ uiView: EmptyBackspaceTextField, context: Context) {
        context.coordinator.parent = self

        if uiView.text != text {
            uiView.text = text
        }

        uiView.placeholder = placeholder
        uiView.onEmptyBackspace = context.coordinator.handleEmptyBackspace

        if isFocused, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: ChecklistTitleTextField

        init(parent: ChecklistTitleTextField) {
            self.parent = parent
        }

        @objc func textDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onBeginEditing()
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.onEndEditing()
        }

        func handleEmptyBackspace() {
            DispatchQueue.main.async {
                self.parent.onEmptyBackspace()
            }
        }
    }

    final class EmptyBackspaceTextField: UITextField {
        var onEmptyBackspace: (() -> Void)?

        override func deleteBackward() {
            if text?.isEmpty ?? true {
                onEmptyBackspace?()
            } else {
                super.deleteBackward()
            }
        }
    }
}
