//
//  HomeScrollEdgeFade.swift
//  SheepDays
//
//  Created by 王飞扬 on 2026/6/12.
//

import SwiftUI

struct HomeScrollEdgeFade: View {
    let edge: VerticalEdge

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThickMaterial)

            Rectangle()
                .fill(Color(.systemGroupedBackground).opacity(0.78))
        }
        .compositingGroup()
        .mask(fadeMask)
        .ignoresSafeArea(.container, edges: ignoredEdges)
    }
}

private extension HomeScrollEdgeFade {
    var fadeMask: LinearGradient {
        let stops: [Gradient.Stop]

        switch edge {
        case .top:
            stops = [
                .init(color: .black.opacity(1.00), location: 0.0),
                .init(color: .black.opacity(0.82), location: 0.68),
                .init(color: .black.opacity(0.48), location: 0.88),
                .init(color: .clear, location: 1.0)
            ]
        case .bottom:
            stops = [
                .init(color: .clear, location: 0.0),
                .init(color: .black.opacity(0.24), location: 0.24),
                .init(color: .black.opacity(0.76), location: 0.66),
                .init(color: .black.opacity(0.96), location: 1.0)
            ]
        }

        return LinearGradient(
            gradient: Gradient(stops: stops),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var ignoredEdges: Edge.Set {
        switch edge {
        case .top:
            return .top
        case .bottom:
            return .bottom
        }
    }
}
