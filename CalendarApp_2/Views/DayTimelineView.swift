//
//  DayTimelineView.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import SwiftUI
import SwiftData

struct DayTimelineView: View {
    private let hourHeight: CGFloat = 64
    private let timeColumnWidth: CGFloat = 56
    private let minimumEventHeight: CGFloat = 32

    let day: Date

    @Query private var events: [CalendarEvent]

    init(day: Date) {
        self.day = day
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day)
        let end = calendar.endOfDay(for: day)
        _events = Query(filter: #Predicate<CalendarEvent> { event in
            event.startDate < end && event.endDate > start
        }, sort: [SortDescriptor(\CalendarEvent.startDate)])
    }

    var body: some View {
        ScrollView(.vertical) {
            ZStack(alignment: .topLeading) {
                timelineGrid
                eventLayer
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }

    private var timelineGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                HStack(alignment: .top, spacing: 12) {
                    Text(String(format: "%02d:00", hour))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: timeColumnWidth, alignment: .trailing)
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 1)
                        .padding(.top, 7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: hourHeight, alignment: .top)
            }
        }
    }

    private var eventLayer: some View {
        GeometryReader { proxy in
            let contentWidth = max(proxy.size.width - timeColumnWidth - 12, 160)
            ZStack(alignment: .topLeading) {
                ForEach(events) { event in
                    TimelineEventView(
                        event: event,
                        dayStart: Calendar.current.startOfDay(for: day),
                        minuteHeight: hourHeight / 60,
                        timeColumnWidth: timeColumnWidth,
                        contentWidth: contentWidth,
                        minimumHeight: minimumEventHeight
                    )
                }
            }
        }
        .frame(height: hourHeight * 24)
    }
}

#Preview {
    DayTimelineView(day: .now)
        .modelContainer(for: CalendarEvent.self, inMemory: true)
}
