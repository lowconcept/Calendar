//
//  TimelineComponents.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import SwiftUI
import UIKit

struct NowLine: View {
    let day: Date

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 30)) { context in
            if Calendar.current.isDateInToday(day) {
                let now = context.date
                let position = timelineOffset(for: now, day: day)
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Rectangle()
                        .fill(Color.red)
                        .frame(height: 2)
                }
                .frame(maxWidth: .infinity)
                .offset(x: CalendarConstants.timelinePaddingLeading, y: position)
                .accessibilityHidden(true)
            }
        }
    }
}

struct GhostEventBlock: View {
    let rect: CGRect

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            .foregroundStyle(Color.white.opacity(0.6))
            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            .frame(width: rect.width, height: rect.height)
            .offset(x: rect.minX, y: rect.minY)
            .allowsHitTesting(false)
    }
}

struct Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

extension Color {
    init(hex: String) {
        let sanitized = hex.replacingOccurrences(of: "#", with: "")
        var hexNumber: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&hexNumber)

        let r = Double((hexNumber & 0xFF0000) >> 16) / 255
        let g = Double((hexNumber & 0x00FF00) >> 8) / 255
        let b = Double(hexNumber & 0x0000FF) / 255

        self = Color(red: r, green: g, blue: b)
    }
}

func timelineOffset(for date: Date, day: Date) -> CGFloat {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: day)
    let minutes = calendar.dateComponents([.minute], from: startOfDay, to: date).minute ?? 0
    return CGFloat(minutes) * CalendarConstants.minuteHeight
}

func minutesFromOffset(_ offset: CGFloat) -> Int {
    Int(offset / CalendarConstants.minuteHeight)
}

func snapMinutes(_ minutes: Int) -> Int {
    let snap = CalendarConstants.snapMinutes
    return Int((Double(minutes) / Double(snap)).rounded()) * snap
}
