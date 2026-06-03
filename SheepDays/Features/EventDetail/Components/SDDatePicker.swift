//
//  SDDatePicker.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/6/3.
//

import SwiftUI

struct SDDatePicker: UIViewRepresentable {
    @Binding var date: Date
    var range: ClosedRange<Date>

    func makeUIView(context: Context) -> UIDatePicker {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        datePicker.minimumDate = range.lowerBound
        datePicker.maximumDate = range.upperBound
        return datePicker
    }

    func updateUIView(_ datePicker: UIDatePicker, context: Context) {
        datePicker.date = date
    }

    func makeCoordinator() -> SDDatePicker.Coordinator {
        Coordinator(date: $date)
    }

    class Coordinator: NSObject {
        private let date: Binding<Date>

        init(date: Binding<Date>) {
            self.date = date
        }

        @objc func changed(_ sender: UIDatePicker) {
            self.date.wrappedValue = sender.date
        }
    }
}
