//
//  TimelineComponents.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 18.01.26.
//

import SwiftUI
import UIKit

struct NowLine: View {
    let leftGutter: CGFloat
    let timelineWidth: CGFloat
    let y: CGFloat

    var body: some View {
        let x0 = leftGutter + 8
        let w = max(0, timelineWidth)

        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color.red.opacity(0.95))
                .frame(width: w, height: 2)
                .position(x: x0 + w / 2, y: y)

            Circle()
                .fill(Color.red.opacity(0.98))
                .frame(width: 8, height: 8)
                .position(x: x0 - 6, y: y)
        }
    }
}

struct GhostEventBlockDarkGlass: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
                    .foregroundStyle(Color.white.opacity(0.24))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

enum Haptics {
    static func tick() {
        #if targetEnvironment(simulator)
        return
        #else
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    static func light() {
        #if targetEnvironment(simulator)
        return
        #else
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        #endif
    }

    static func strong() {
        #if targetEnvironment(simulator)
        return
        #else
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        #endif
    }
}
