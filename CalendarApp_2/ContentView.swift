//
//  ContentView.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()
    @State private var events: [CalendarEvent] = CalendarEvent.sample
    @State private var isPresentingAddEvent = false

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                header
                weekdayHeader
                calendarGrid
                eventSection
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingAddEvent = true
                    } label: {
                        Label("Add Event", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddEvent) {
                AddEventView(selectedDate: selectedDate) { newEvent in
                    events.append(newEvent)
                    selectedDate = newEvent.date
                    displayedMonth = newEvent.date
                }
            }
            .navigationTitle("My Calendar")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.left")
                    .padding(8)
                    .background(.thinMaterial, in: Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(monthTitle(from: displayedMonth))
                    .font(.title2.weight(.semibold))
                Text("Tap a day to see details")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.right")
                    .padding(8)
                    .background(.thinMaterial, in: Circle())
            }
        }
    }

    private var weekdayHeader: some View {
        let symbols = calendar.shortWeekdaySymbols
        return HStack(spacing: 0) {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol.uppercased())
                    .font(.caption2.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var calendarGrid: some View {
        let days = daysInMonth(for: displayedMonth)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(days) { day in
                Button {
                    selectedDate = day.date
                } label: {
                    VStack(spacing: 6) {
                        Text(day.label)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(day.isInDisplayedMonth ? .primary : .secondary)
                            .frame(maxWidth: .infinity)

                        if hasEvents(on: day.date) {
                            Circle()
                                .fill(day.isSelected ? Color.white : Color.accentColor)
                                .frame(width: 6, height: 6)
                                .opacity(day.isInDisplayedMonth ? 1 : 0.3)
                        } else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(day.isSelected ? Color.accentColor : Color.clear, in: RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        if day.isToday {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.accentColor, lineWidth: 1)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var eventSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Events")
                    .font(.headline)
                Spacer()
                Text(dayDetailTitle(selectedDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            let dayEvents = eventsForSelectedDate
            if dayEvents.isEmpty {
                ContentUnavailableView("No events", systemImage: "calendar.badge.clock", description: Text("Plan something for this day."))
                    .frame(maxWidth: .infinity, minHeight: 140)
            } else {
                ForEach(dayEvents) { event in
                    EventRow(event: event)
                }
            }

            Text("Upcoming")
                .font(.headline)
                .padding(.top, 8)

            let upcomingEvents = upcomingEventsList
            if upcomingEvents.isEmpty {
                Text("No upcoming events")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(upcomingEvents) { event in
                    EventRow(event: event)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var eventsForSelectedDate: [CalendarEvent] {
        events
            .filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted(by: { $0.startTime < $1.startTime })
    }

    private var upcomingEventsList: [CalendarEvent] {
        let upcoming = events
            .filter { $0.date >= calendar.startOfDay(for: selectedDate) }
            .sorted(by: { $0.date < $1.date })
        return Array(upcoming.prefix(3))
    }

    private func monthTitle(from date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }

    private func dayDetailTitle(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))
    }

    private func daysInMonth(for date: Date) -> [CalendarDay] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let firstWeekInterval = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let lastWeekInterval = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end.addingTimeInterval(-1))
        else {
            return []
        }

        let startDate = firstWeekInterval.start
        let endDate = lastWeekInterval.end
        var days: [CalendarDay] = []
        var currentDate = startDate

        while currentDate < endDate {
            let isInDisplayedMonth = calendar.isDate(currentDate, equalTo: date, toGranularity: .month)
            let isToday = calendar.isDateInToday(currentDate)
            let isSelected = calendar.isDate(currentDate, inSameDayAs: selectedDate)
            let label = String(calendar.component(.day, from: currentDate))
            days.append(CalendarDay(date: currentDate, label: label, isInDisplayedMonth: isInDisplayedMonth, isToday: isToday, isSelected: isSelected))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate.addingTimeInterval(86_400)
        }

        return days
    }

    private func hasEvents(on date: Date) -> Bool {
        events.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }
}

struct EventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(event.color)
                .frame(width: 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                Text(event.timeRangeText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !event.location.isEmpty {
                    Label(event.location, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var date: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var location = ""
    @State private var notes = ""
    @State private var color = Color.blue

    let onSave: (CalendarEvent) -> Void

    init(selectedDate: Date, onSave: @escaping (CalendarEvent) -> Void) {
        let calendar = Calendar.current
        let initialDate = calendar.startOfDay(for: selectedDate)
        _date = State(initialValue: initialDate)
        _startTime = State(initialValue: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? selectedDate)
        _endTime = State(initialValue: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: selectedDate) ?? selectedDate)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    DatePicker("Starts", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("Ends", selection: $endTime, displayedComponents: .hourAndMinute)
                    TextField("Location", text: $location)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }

                Section("Color") {
                    ColorPicker("Tag", selection: $color, supportsOpacity: false)
                }
            }
            .navigationTitle("New Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let event = CalendarEvent(
                            title: title.isEmpty ? "Untitled Event" : title,
                            date: date,
                            startTime: startTime,
                            endTime: max(startTime, endTime),
                            location: location,
                            notes: notes,
                            color: color
                        )
                        onSave(event)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let label: String
    let isInDisplayedMonth: Bool
    let isToday: Bool
    let isSelected: Bool
}

struct CalendarEvent: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let date: Date
    let startTime: Date
    let endTime: Date
    let location: String
    let notes: String
    let color: Color

    var timeRangeText: String {
        let start = startTime.formatted(.dateTime.hour().minute())
        let end = endTime.formatted(.dateTime.hour().minute())
        return "\(start) – \(end)"
    }

    static let sample: [CalendarEvent] = [
        CalendarEvent(
            title: "Team Sync",
            date: Date(),
            startTime: Calendar.current.date(byAdding: .hour, value: 9, to: Date()) ?? Date(),
            endTime: Calendar.current.date(byAdding: .hour, value: 10, to: Date()) ?? Date(),
            location: "Studio A",
            notes: "Discuss weekly priorities.",
            color: .blue
        ),
        CalendarEvent(
            title: "Lunch with Jo",
            date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            startTime: Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: Date()) ?? Date(),
            endTime: Calendar.current.date(bySettingHour: 13, minute: 30, second: 0, of: Date()) ?? Date(),
            location: "Central Cafe",
            notes: "Catch up over lunch.",
            color: .orange
        ),
        CalendarEvent(
            title: "Product Review",
            date: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
            startTime: Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date(),
            endTime: Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date(),
            location: "Conference Room",
            notes: "Review Q2 roadmap.",
            color: .purple
        )
    ]
}

#Preview {
    ContentView()
}
