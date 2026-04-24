//
//  SymbolPickerView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/18.
//

import SwiftUI

struct SymbolPickerView: View {
    let title: String
    let sections: [SFSymbolSection]
    let selectedSystemName: String?
    let tintColor: Color
    let onSelect: (String?) -> Void
    let onClose: () -> Void
    
    @State private var stagedSystemName: String?

    init(
        title: String,
        sections: [SFSymbolSection],
        selectedSystemName: String?,
        tintColor: Color,
        onSelect: @escaping (String?) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.title = title
        self.sections = sections
        self.selectedSystemName = selectedSystemName
        self.tintColor = tintColor
        self.onSelect = onSelect
        self.onClose = onClose
        _stagedSystemName = State(initialValue: selectedSystemName)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider()
                .padding(.horizontal)
                .padding(.vertical, 20)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(sections) { section in
                        SymbolPickerSectionView(
                            section: section,
                            selectedSystemName: stagedSystemName,
                            tintColor: tintColor,
                            onSelect: handleSelect
                        )
                    }
                }
            }
        }
        .onAppear {
            stagedSystemName = selectedSystemName
        }
        .padding(.horizontal, 15)
        .padding(.top, 20)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.18), radius: 28, y: 3)
        )
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(.secondaryLabel))
                
                Spacer()

                SDHeaderActionButton(iconSystemName: "xmark", action: onClose)
            }

            HStack {
                Image(systemName: stagedSystemName ?? "questionmark.circle")
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .foregroundStyle(tintColor)
                    .frame(width: 60, height: 50)
                
                Spacer()
            }
        }
    }

    private func handleSelect(_ systemName: String) {
        stagedSystemName = systemName
        onSelect(systemName)
    }
}

#Preview {
    SymbolPickerView(
        title: "选择事件图标",
        sections: SFSymbolLibrary.eventSections,
        selectedSystemName: "calendar.badge.clock",
        tintColor: .orange,
        onSelect: { _ in },
        onClose: {}
    )
    .padding()
    .background(Color(.secondarySystemBackground))
}
