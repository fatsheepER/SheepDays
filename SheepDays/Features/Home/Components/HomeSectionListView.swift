//
//  HomeSectionListView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/6/12.
//

import SwiftUI

struct HomeSectionListView<EmptyContent: View>: View {
    let sections: [HomeSection]
    let targetDatesByEventID: [UUID: Date]
    let badgeDisplayMode: SDEventItemBadgeDisplayMode
    let isBottomSheetPresented: Bool
    let emptyContent: EmptyContent
    let openDetail: (UUID) -> Void
    let jumpToEventDate: (Date?) -> Void
    let setRelativeValue: (Date?) -> Void

    init(
        sections: [HomeSection],
        targetDatesByEventID: [UUID: Date],
        badgeDisplayMode: SDEventItemBadgeDisplayMode,
        isBottomSheetPresented: Bool,
        @ViewBuilder emptyContent: () -> EmptyContent,
        openDetail: @escaping (UUID) -> Void,
        jumpToEventDate: @escaping (Date?) -> Void,
        setRelativeValue: @escaping (Date?) -> Void
    ) {
        self.sections = sections
        self.targetDatesByEventID = targetDatesByEventID
        self.badgeDisplayMode = badgeDisplayMode
        self.isBottomSheetPresented = isBottomSheetPresented
        self.emptyContent = emptyContent()
        self.openDetail = openDetail
        self.jumpToEventDate = jumpToEventDate
        self.setRelativeValue = setRelativeValue
    }

    var body: some View {
        ZStack {
            if sections.isEmpty {
                emptyContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ZStack(alignment: .bottom) {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            sectionList
                        }
                        .safeAreaInset(edge: .bottom) {
                            if isBottomSheetPresented {
                                bottomInsetContent
                            }
                        }
                        .padding(.horizontal)
                    }

                    if isBottomSheetPresented {
                        HomeScrollEdgeFade(edge: .bottom)
                            .frame(height: HomeSectionListMetrics.bottomScrollFadeHeight)
                            .padding(.horizontal, -HomeSectionListMetrics.edgeFadeHorizontalBleed)
                            .offset(y: HomeSectionListMetrics.bottomScrollFadeOffset)
                            .allowsHitTesting(false)
                            .zIndex(1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private extension HomeSectionListView {
    var sectionList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Color.clear.frame(height: HomeSectionListMetrics.floatingDateScrollInset)

            ForEach(sections) { section in
                homeSection(section)
                    .transition(.scale.combined(with: .blurReplace))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func homeSection(_ section: HomeSection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title = section.title, !title.isEmpty {
                SectionHeaderView(title: title)
                    .padding(.horizontal)
            }

            VStack(spacing: 0) {
                ForEach(section.items) { item in
                    let badgeDate = targetDatesByEventID[item.sourceEventId]

                    HomeEventItemView(
                        item: item,
                        badgeDisplayMode: badgeDisplayMode,
                        badgeDate: badgeDate,
                        openDetail: { openDetail(item.sourceEventId) },
                        jumpToEventDate: { jumpToEventDate(badgeDate) },
                        setRelativeValue: { setRelativeValue(badgeDate) }
                    )
                    .id(item.id)
                    .transition(.blurReplace.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(homeSectionBackground)
        }
    }

    var homeSectionBackground: some View {
        RoundedRectangle(cornerRadius: 35, style: .continuous)
            .foregroundStyle(Color(.secondarySystemGroupedBackground))
    }

    var bottomInsetContent: some View {
        VStack {
            Text("Sheep Days")
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(Color(.tertiaryLabel))

            Text("Made with LOVE since Apr 15, 2026")
                .font(.system(size: 10, weight: .regular, design: .serif))
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .frame(height: HomeSectionListMetrics.bottomSheetInsetHeight)
    }
}

private enum HomeSectionListMetrics {
    static let floatingDateScrollInset: CGFloat = 160
    static let bottomScrollFadeHeight: CGFloat = 172
    static let bottomScrollFadeOffset: CGFloat = 64
    static let bottomSheetInsetHeight: CGFloat = 200
    static let edgeFadeHorizontalBleed: CGFloat = 42
}
