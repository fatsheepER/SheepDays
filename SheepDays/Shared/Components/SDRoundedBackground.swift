//
//  SDRoundedBackground.swift
//  SheepDays
//
//  Created by Codex on 2026/4/2.
//

import SwiftUI

struct SDRoundedCornersShape: Shape {
    let topLeading: CGFloat
    let topTrailing: CGFloat
    let bottomLeading: CGFloat
    let bottomTrailing: CGFloat
    let style: RoundedCornerStyle

    init(
        topLeading: CGFloat = 0,
        topTrailing: CGFloat = 0,
        bottomLeading: CGFloat = 0,
        bottomTrailing: CGFloat = 0,
        style: RoundedCornerStyle = .continuous
    ) {
        self.topLeading = topLeading
        self.topTrailing = topTrailing
        self.bottomLeading = bottomLeading
        self.bottomTrailing = bottomTrailing
        self.style = style
    }

    var cornerRadii: RectangleCornerRadii {
        RectangleCornerRadii(
            topLeading: topLeading,
            bottomLeading: bottomLeading,
            bottomTrailing: bottomTrailing,
            topTrailing: topTrailing
        )
    }

    func path(in rect: CGRect) -> Path {
        UnevenRoundedRectangle(cornerRadii: cornerRadii, style: style)
            .path(in: rect)
    }
}

struct SDRoundedBackground: View {
    private let shapeStyle: AnyShapeStyle
    private let topLeading: CGFloat
    private let topTrailing: CGFloat
    private let bottomLeading: CGFloat
    private let bottomTrailing: CGFloat
    private let cornerStyle: RoundedCornerStyle

    init(
        topLeading: CGFloat = 0,
        topTrailing: CGFloat = 0,
        bottomLeading: CGFloat = 0,
        bottomTrailing: CGFloat = 0,
        cornerStyle: RoundedCornerStyle = .continuous,
        color: some ShapeStyle
    ) {
        self.topLeading = topLeading
        self.topTrailing = topTrailing
        self.bottomLeading = bottomLeading
        self.bottomTrailing = bottomTrailing
        self.cornerStyle = cornerStyle
        self.shapeStyle = AnyShapeStyle(color)
    }

    var body: some View {
        SDRoundedCornersShape(
            topLeading: topLeading,
            topTrailing: topTrailing,
            bottomLeading: bottomLeading,
            bottomTrailing: bottomTrailing,
            style: cornerStyle
        )
        .fill(shapeStyle)
    }
}

extension View {
    func sdRoundedBackground(
        topLeading: CGFloat = 0,
        topTrailing: CGFloat = 0,
        bottomLeading: CGFloat = 0,
        bottomTrailing: CGFloat = 0,
        cornerStyle: RoundedCornerStyle = .continuous,
        color: some ShapeStyle
    ) -> some View {
        background {
            SDRoundedBackground(
                topLeading: topLeading,
                topTrailing: topTrailing,
                bottomLeading: bottomLeading,
                bottomTrailing: bottomTrailing,
                cornerStyle: cornerStyle,
                color: color
            )
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        SDRoundedBackground(
            topLeading: 30,
            topTrailing: 30,
            bottomLeading: 10,
            bottomTrailing: 10,
            color: Color(.secondarySystemBackground)
        )
        .frame(height: 130)
        
        HStack(spacing: 10) {
            SDRoundedBackground(
                topLeading: 10,
                topTrailing: 10,
                bottomLeading: 30,
                bottomTrailing: 10,
                color: Color(.secondarySystemBackground)
            )
            .frame(height: 60)
            
            SDRoundedBackground(
                topLeading: 10,
                topTrailing: 10,
                bottomLeading: 10,
                bottomTrailing: 30,
                color: Color(.secondarySystemBackground)
            )
            .frame(height: 60)
        }
    }
    .frame(maxWidth: .infinity)
    .padding()
}
