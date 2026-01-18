//
//  TimelineEventView.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import SwiftUI

struct TimelineEventView: View {
    let event: CalendarEvent
    let dayStart: Date
    let minuteHeight: CGFloat
    let timeColumnWidth: CGFloat
    let contentWidth: CGFloat
    let minimumHeight: CGFloat

    private var offsetMinutes: CGFloat {
        let minutes = Calendar.current.dateComponents([.minute], from: dayStart, to: event.startDate).minute ?? 0
        return CGFloat(max(minutes, 0))
    }

    private var durationMinutes: CGFloat {
        let minutes = Calendar.current.dateComponents([.minute], from: event.startDate, to: event.endDate).minute ?? 0
        return CGFloat(max(minutes, 15))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(timeRangeDisplay)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let notes = event.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .frame(width: contentWidth, height: max(durationMinutes * minuteHeight, minimumHeight), alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.accentColor.opacity(0.18)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.accentColor.opacity(0.35), lineWidth: 1))
        .offset(x: timeColumnWidth + 12, y: offsetMinutes * minuteHeight)
    }

    private var timeRangeDisplay: String {
        let start = event.startDate.formatted(.dateTime.hour().minute())
        let end = event.endDate.formatted(.dateTime.hour().minute())
        return "\(start) – \(end)"
    }
}

#Preview {
    let now = Date()
    let sample = CalendarEvent(title: "Design Review", startDate: now, endDate: Calendar.current.date(byAdding: .minute, value: 90, to: now)!)
    return TimelineEventView(
        event: sample,
        dayStart: Calendar.current.startOfDay(for: now),
        minuteHeight: 1,
        timeColumnWidth: 56,
        contentWidth: 220,
        minimumHeight: 32
    )
}
