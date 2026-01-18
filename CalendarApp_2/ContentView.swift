//
//  ContentView.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedDate = Date()
    @State private var weekStart = Calendar.current.startOfDay(for: Date())
    @State private var events: [CalendarEvent] = CalendarEvent.sample

    private let calendar = Calendar.current

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                header
                weekStrip
                timeline
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)

            bottomBar
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(headerDayTitle)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(headerMonthTitle)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            HStack(spacing: 16) {
                Button {
                    // Placeholder for accounts
                } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Button {
                    // Placeholder for filters
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private var weekStrip: some View {
        let days = daysForWeek(starting: weekStart)
        return HStack(spacing: 12) {
            ForEach(days) { day in
                VStack(spacing: 6) {
                    Text(day.weekday)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(day.day)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(day.isSelected ? Color.white : Color.white.opacity(0.8))
                        .frame(width: 34, height: 34)
                        .background(day.isSelected ? Color.red : Color.clear, in: Circle())
                }
                .onTapGesture {
                    selectedDate = day.date
                }
            }
        }
    }

    private var timeline: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(0..<24, id: \.self) { hour in
                        TimelineHourRow(hour: hour)
                    }
                }
                .padding(.bottom, 120)
                .overlay(alignment: .topLeading) {
                    ForEach(eventsForSelectedDate) { event in
                        TimelineEventCard(event: event, startDate: selectedDate)
                    }
                }
                .overlay(alignment: .topLeading) {
                    CurrentTimeIndicator(selectedDate: selectedDate)
                }
            }
            .onAppear {
                let currentHour = calendar.component(.hour, from: Date())
                withAnimation(.easeInOut(duration: 0.4)) {
                    proxy.scrollTo(currentHour, anchor: .top)
                }
            }
        }
    }

    private var bottomBar: some View {
        VStack {
            Spacer()
            HStack(spacing: 28) {
                Image(systemName: "person.crop.circle")
                Image(systemName: "magnifyingglass")
                Text("Calendar")
                    .font(.headline.weight(.semibold))
                Image(systemName: "plus")
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(.white.opacity(0.2), in: Capsule())
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
    }

    private var headerDayTitle: String {
        selectedDate.formatted(.dateTime.weekday(.abbreviated)) + " " + selectedDate.formatted(.dateTime.day())
    }

    private var headerMonthTitle: String {
        selectedDate.formatted(.dateTime.month(.abbreviated).year())
    }

    private var eventsForSelectedDate: [CalendarEvent] {
        events.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private func daysForWeek(starting start: Date) -> [WeekdayItem] {
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? start
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek) else { return nil }
            let weekday = date.formatted(.dateTime.weekday(.narrow))
            let day = date.formatted(.dateTime.day())
            return WeekdayItem(date: date, weekday: weekday, day: day, isSelected: calendar.isDate(date, inSameDayAs: selectedDate))
        }
    }
}

struct TimelineHourRow: View {
    let hour: Int

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(String(format: "%02d:00", hour))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.35))
                .frame(width: 52, alignment: .trailing)
                .padding(.top, -6)

            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 1)
                .padding(.top, 6)
        }
        .frame(height: 64)
        .id(hour)
    }
}

struct TimelineEventCard: View {
    let event: CalendarEvent
    let startDate: Date

    private let calendar = Calendar.current

    var body: some View {
        let start = calendar.component(.hour, from: event.startTime)
        let minutes = calendar.component(.minute, from: event.startTime)
        let offsetY = CGFloat(start) * 64 + CGFloat(minutes) / 60 * 64
        let duration = max(event.durationMinutes, 30)
        let height = CGFloat(duration) / 60 * 64

        HStack(spacing: 10) {
            Rectangle()
                .fill(event.color)
                .frame(width: 4)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(event.timeRangeText)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 48, height: 6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(event.color.opacity(0.25), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(event.color.opacity(0.5), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
        .offset(x: 68, y: offsetY)
    }
}

struct CurrentTimeIndicator: View {
    let selectedDate: Date

    private let calendar = Calendar.current

    var body: some View {
        if calendar.isDateInToday(selectedDate) {
            let now = Date()
            let hour = calendar.component(.hour, from: now)
            let minute = calendar.component(.minute, from: now)
            let offsetY = CGFloat(hour) * 64 + CGFloat(minute) / 60 * 64

            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Rectangle()
                    .fill(Color.red)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
            .offset(x: 68, y: offsetY)
        }
    }
}

struct WeekdayItem: Identifiable {
    let id = UUID()
    let date: Date
    let weekday: String
    let day: String
    let isSelected: Bool
}

struct CalendarEvent: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let date: Date
    let startTime: Date
    let endTime: Date
    let color: Color

    var durationMinutes: Int {
        max(Int(endTime.timeIntervalSince(startTime) / 60), 15)
    }

    var timeRangeText: String {
        let start = startTime.formatted(.dateTime.hour().minute())
        let end = endTime.formatted(.dateTime.hour().minute())
        return "\(start) – \(end)"
    }

    static let sample: [CalendarEvent] = [
        CalendarEvent(
            title: "1. Task",
            date: Date(),
            startTime: Calendar.current.date(byAdding: .minute, value: -10, to: Date()) ?? Date(),
            endTime: Calendar.current.date(byAdding: .minute, value: 52, to: Date()) ?? Date(),
            color: .red
        )
    ]
}

#Preview {
    ContentView()
}
