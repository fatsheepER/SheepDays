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
        VStack(spacing: 10) {
            VStack(spacing: 10) {
                header
                    .padding(.bottom, 10)

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
            .padding(.horizontal, 15)
            .padding(.top, 20)
            
            controls
        }
        .onAppear {
            stagedSystemName = selectedSystemName
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.18), radius: 28, y: 3)
        )
    }

    private var header: some View {
        VStack {
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(.secondaryLabel))
                
                Spacer()
            }
            .padding(.bottom, 10)
            
            HStack {
                Image(systemName: stagedSystemName ?? "questionmark.circle")
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .foregroundStyle(tintColor)
                    .frame(width: 60, height: 50)
                
                Spacer()
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button {
                stagedSystemName = nil
                onSelect(nil)
            } label: {
                SDSheetActionButton(iconSystemName: "nosign", title: "清除图标", placement: .left, style: .secondary)
            }
            .buttonStyle(.plain)

            Button(action: onClose) {
                SDSheetActionButton(iconSystemName: "checkmark", title: "应用", placement: .right, style: .prominent)
            }
            .buttonStyle(.plain)
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
