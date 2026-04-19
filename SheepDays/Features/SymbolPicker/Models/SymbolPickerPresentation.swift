//
//  SymbolPickerPresentation.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/18.
//

import SwiftUI

struct SymbolPickerPresentation: Identifiable {
    let id = UUID()
    let title: String
    let sections: [SFSymbolSection]
    let selectedSystemName: String?
    let tintColor: Color
    let onSelect: (String?) -> Void
}
