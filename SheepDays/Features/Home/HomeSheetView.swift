//
//  HomeSheet.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import SwiftUI

struct HomeSheetView: View {
    @Binding var referenceDate: Date
    let badgeDisplayMode: HomeItemBadgeDisplayMode

    var onTapFocus: () -> Void = {}
    var onTapQuickAdd: () -> Void = {}
    var onTapNotebooks: () -> Void = {}
    var onTapSettings: () -> Void = {}
    var onTapToday: () -> Void = {}
    var onToggleBadgeDisplayMode: () -> Void = {}

    var body: some View {
        VStack(spacing: 10) {
            topBar
                .padding(.horizontal, 10)
            actionRow
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
//        .padding(10)
    }
}

// MARK: - Subviews
private extension HomeSheetView {
    var topBar: some View {
        HStack(spacing: 15) {
            Button(action: onToggleBadgeDisplayMode) {
                Image(systemName: badgeDisplayModeToggleIcon)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .background(
                        Circle()
                            .fill(Color.accentColorSecondary)
                            .frame(width: 30, height: 30)
                    )
                    .foregroundStyle(.accent)
            }
            .buttonStyle(.plain)
            
            CapsuleRollerView(adjustedDate: $referenceDate, lineSpacing: 8, lineHeight: 30)
                .frame(maxWidth: .infinity)

            Button(action: onTapToday) {
                Image(systemName: "smallcircle.filled.circle")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .background(
                        Circle()
                            .fill(Color.accentColorSecondary)
                            .frame(width: 30, height: 30)
                    )
                    .foregroundStyle(.accent)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 30)
    }

    var actionRow: some View {
        HStack(spacing: 10) {
            HomeSheetActionCard(title: "聚焦",
                                systemImage: "eye",
                                action: onTapFocus)

            HomeSheetActionCard(title: "创建新事件",
                                systemImage: "plus",
                                action: onTapQuickAdd)

            HomeSheetActionCard(title: "事件本",
                                systemImage: "list.bullet",
                                action: onTapNotebooks)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var badgeDisplayModeToggleIcon: String {
        switch badgeDisplayMode {
        case .relativeText:
            return "number"
        case .date:
            return "calendar"
        }
    }
}

#Preview {
    @Previewable @State var referenceDate = Calendar.current.startOfDay(for: .now)

    HomeSheetView(referenceDate: $referenceDate, badgeDisplayMode: .relativeText)
        .padding()
        .background(Color(.systemGroupedBackground))
}
