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
    let recentSymbolLimit: Int
    let onSelect: (String?) -> Void
    let onClose: () -> Void
    
    @State private var stagedSystemName: String?
    @State private var recentSystemNames: [String]

    private let recentSymbolStore: RecentSFSymbolStore

    init(
        title: String,
        sections: [SFSymbolSection],
        selectedSystemName: String?,
        tintColor: Color,
        recentSymbolLimit: Int = SymbolPickerPresentation.defaultRecentSymbolLimit,
        recentSymbolStore: RecentSFSymbolStore = .shared,
        onSelect: @escaping (String?) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.title = title
        self.sections = sections
        self.selectedSystemName = selectedSystemName
        self.tintColor = tintColor
        self.recentSymbolLimit = recentSymbolLimit
        self.recentSymbolStore = recentSymbolStore
        self.onSelect = onSelect
        self.onClose = onClose
        _stagedSystemName = State(initialValue: selectedSystemName)
        _recentSystemNames = State(initialValue: recentSymbolStore.load(limit: recentSymbolLimit))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider()
                .padding(.horizontal)
                .padding(.vertical, 20)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        if recentSymbolLimit > 0 {
                            SymbolPickerSectionView(
                                section: recentSection,
                                selectedSystemName: stagedSystemName,
                                tintColor: tintColor,
                                placeholderCount: recentPlaceholderCount,
                                onSelect: handleSelect
                            )
                        }

                        ForEach(sections) { section in
                            SymbolPickerSectionView(
                                section: section,
                                selectedSystemName: stagedSystemName,
                                tintColor: tintColor,
                                placeholderCount: 0,
                                onSelect: handleSelect
                            )
                        }
                    }
                    .padding(.horizontal, 2) // to avoid covered stroke
                }
            }
        }
        .onAppear {
            stagedSystemName = selectedSystemName
            recentSystemNames = recentSymbolStore.load(limit: recentSymbolLimit)
        }
        .padding(.horizontal, 23)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.18), radius: 28, y: 3)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .stroke(Color(.separator), lineWidth: 2)
        }
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
                    .contentTransition(.symbolEffect)
                
                Spacer()
            }
        }
        .animation(.bouncy(duration: 0.1), value: stagedSystemName)
    }

    private var recentSection: SFSymbolSection {
        SFSymbolSection(title: "最近使用", symbols: recentSymbols)
    }

    private var recentSymbols: [SFSymbolChoice] {
        let recentSymbols = recentSystemNames
            .compactMap { symbolChoice(for: $0) }
            .prefix(recentSymbolLimit)

        return Array(recentSymbols)
    }

    private var recentPlaceholderCount: Int {
        max(0, recentSymbolLimit - recentSymbols.count)
    }

    private func symbolChoice(for systemName: String) -> SFSymbolChoice? {
        for section in sections {
            if let symbol = section.symbols.first(where: { $0.systemName == systemName }) {
                return symbol
            }
        }

        return nil
    }

    private func handleSelect(_ systemName: String) {
        stagedSystemName = systemName
        recentSystemNames = recentSymbolStore.record(systemName, limit: recentSymbolLimit)
        onSelect(systemName)
    }
}

#Preview {
    SymbolPickerView(
        title: "选择事件图标",
        sections: SFSymbolLibrary.generalSections,
        selectedSystemName: "calendar.badge.clock",
        tintColor: .orange,
        recentSymbolLimit: SymbolPickerPresentation.defaultRecentSymbolLimit,
        onSelect: { _ in },
        onClose: {}
    )
    .padding(.horizontal, 40)
    .frame(maxHeight: 600)
    .background(Color(.secondarySystemBackground))
}
