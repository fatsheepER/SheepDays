//
//  CapsuleRoller.swift
//  Sheep Days
//
//  Created by 王飞扬 on 2025/5/9.
//

import SwiftUI

struct CapsuleRollerView: View {
    @Binding var adjustedDate: Date

    let lineSpacing: CGFloat
    let lineHeight: CGFloat

    private let centerIndex = 149
    private let lineWidth: CGFloat = 5
    private let baselineVisibleLineCount = 24.0
    private let baselineAdjustmentFactor = 1.5

    @State private var scrollIndex: Int?
    @State private var resetTask: DispatchWorkItem?
    @State private var isResetting = false

    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)

    init(adjustedDate: Binding<Date>, lineSpacing: CGFloat = 5, lineHeight: CGFloat = 60) {
        _adjustedDate = adjustedDate
        self.lineSpacing = lineSpacing
        self.lineHeight = lineHeight
    }

    var body: some View {
        GeometryReader { proxy in
            let visibleLineCount = self.visibleLineCount(for: proxy.size.width)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: lineSpacing) {
                    ForEach(0..<(centerIndex * 2), id: \.self) { index in
                        Capsule()
                            .frame(width: lineWidth, height: lineHeight)
                            .foregroundStyle(.gray.secondary)
                            .id(index)
                            .scrollTransition { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1.0 : 0.1)
                                    .scaleEffect(x: phase.isIdentity ? 1.0 : 0.3,
                                                 y: phase.isIdentity ? 1.0 : 0.3)
                            }
                    }
                }
                .frame(height: lineHeight)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrollIndex, anchor: .leading)
            .onAppear {
                scrollIndex = centerIndex
                hapticGenerator.prepare()
            }
            .onChange(of: scrollIndex) { previousValue, newValue in
                guard let unwrappedPreviousValue = previousValue, let unwrappedNewValue = newValue else {
                    return
                }

                // 1. 拦截复位操作触发的 onChange
                if isResetting {
                    // 当发现确实回到了中心点时，消耗掉这个标志位
                    if unwrappedNewValue == centerIndex {
                        isResetting = false
                    }
                    return // 直接返回，不参与后面的计算和计时器重置
                }
                
                // 2. 处理正常的用户滑动操作
                if unwrappedPreviousValue != unwrappedNewValue {
                    hapticGenerator.impactOccurred()
                    
                    var delta = unwrappedNewValue - unwrappedPreviousValue
                    let factor = adjustmentFactor(for: visibleLineCount)
                    let adjusted = (Double(abs(delta)) / factor).rounded(.up)
                    delta = Int(adjusted) * delta.signum()
                    
                    withAnimation {
                        if let updatedDate = Calendar.current.date(byAdding: .day, value: delta, to: adjustedDate) {
                            adjustedDate = updatedDate
                        }
                    }
                }
                
                // 3. 防抖策略：重置静默复位计时器
                resetTask?.cancel()
                
                let task = DispatchWorkItem {
                    // 仅当当前不在中心点时，才需要发起复位操作，防止标志位被错误锁定
                    guard self.scrollIndex != self.centerIndex else { return }
                    
                    self.isResetting = true
                    self.scrollIndex = self.centerIndex
                }
                self.resetTask = task
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: task)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: lineHeight)
    }
}

private extension CapsuleRollerView {
    var baselineDaysPerScreen: Double {
        baselineVisibleLineCount / baselineAdjustmentFactor
    }

    func visibleLineCount(for availableWidth: CGFloat) -> Double {
        let stride = max(lineWidth + lineSpacing, 1)
        return max(Double(availableWidth / stride), 1)
    }

    func adjustmentFactor(for visibleLineCount: Double) -> Double {
        max(visibleLineCount / baselineDaysPerScreen, 1)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

#Preview {
    @Previewable @State var date = Date()
    VStack {
        Text("\(date.formatted(date: .abbreviated, time: .omitted))")

        CapsuleRollerView(adjustedDate: $date, lineSpacing: 5, lineHeight: 60)
    }

}
