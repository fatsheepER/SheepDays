//
//  FocusSheetView.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/4/1.
//

import SwiftUI

struct FocusSheetView: View {
    @Binding var focusState: HomeFocusState

    @State private var isShowingAdvancedOptions = false

    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 15) {
            header

            Group {
                if isShowingAdvancedOptions {
                    advancedOptionsPlaceholder
                } else {
                    bentoPlaceholder
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            controls
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private extension FocusSheetView {
    var header: some View {
        HStack {
            SDSheetTitleView(iconSystemName: "eye", title: "聚焦")

            Spacer()

            Text(summaryText)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .foregroundStyle(Color(.secondarySystemBackground))
                )
        }
    }

    var bentoPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.secondary)

            Text("聚焦条件面板待实现")
                .font(.headline)

            Text("底层筛选、排序和分组状态已经接通。下一步可以直接在这里接入 bento UI。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            SDRoundedBackground(
                topLeading: 35,
                topTrailing: 35,
                bottomLeading: 10,
                bottomTrailing: 10,
                cornerStyle: .continuous,
                color: Color(.systemBackground)
            )
        )
    }

    var advancedOptionsPlaceholder: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                placeholderRow(
                    title: "来源范围",
                    detail: "事件本与标签的高级配置稍后接入"
                )
                placeholderRow(
                    title: "时间范围",
                    detail: "精细时间窗口规则稍后接入"
                )
                placeholderRow(
                    title: "排序方式",
                    detail: "排序条件的高级选项稍后接入"
                )
                placeholderRow(
                    title: "分组方式",
                    detail: "分组条件的高级选项稍后接入"
                )
            }
        }
    }

    func placeholderRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            Text(detail)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            SDRoundedBackground(
                topLeading: 24,
                topTrailing: 24,
                bottomLeading: 10,
                bottomTrailing: 10,
                cornerStyle: .continuous,
                color: Color(.systemBackground)
            )
        )
    }

    var controls: some View {
        HStack {
            Button(action: restorePreset) {
                SDSheetActionButton(
                    iconSystemName: "arrow.uturn.backward",
                    title: "还原",
                    placement: .left,
                    style: .plain
                )
            }
            .buttonStyle(.plain)

            Button(action: toggleAdvancedOptions) {
                SDSheetActionButton(
                    iconSystemName: isShowingAdvancedOptions ? "square.grid.2x2" : "ellipsis",
                    title: isShowingAdvancedOptions ? "收起" : "更多",
                    placement: .middle,
                    style: .plain
                )
            }
            .buttonStyle(.plain)

            Button(action: onBack) {
                SDSheetActionButton(
                    iconSystemName: "checkmark",
                    title: "应用",
                    placement: .right,
                    style: .prominent
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 5)
    }

    var summaryText: String {
        "\(activeFilterCount) 项"
    }

    var activeFilterCount: Int {
        var count = 0

        if !focusState.selectedNotebookIDs.isEmpty {
            count += 1
        }

        if !focusState.selectedTagIDs.isEmpty {
            count += 1
        }

        if focusState.timeRange != .all {
            count += 1
        }

        if focusState.sortMode != .targetDateAscending {
            count += 1
        }

        if focusState.groupingMode != .none {
            count += 1
        }

        return count
    }

    func restorePreset() {
        // Preset restore will be implemented with the future preset feature.
    }

    func toggleAdvancedOptions() {
        withAnimation(.spring(duration: 0.2)) {
            isShowingAdvancedOptions.toggle()
        }
    }
}

#Preview {
    @Previewable @State var focusState = HomeFocusState()

    FocusSheetView(
        focusState: $focusState,
        onBack: {}
    )
    .padding()
}
