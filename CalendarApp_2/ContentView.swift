//
//  ContentView.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import SwiftUI

struct TimelineEvent: Identifiable {
    let id = UUID()
    let title: String
    let timeRange: String
    let location: String
    let color: Color
    let startHour: Int
}

struct ContentView: View {
    private let hours = Array(8...19)

    private let events: [TimelineEvent] = [
        TimelineEvent(
            title: "Produkt-Standup",
            timeRange: "09:00 – 09:30",
            location: "Studio B",
            color: Color.blue,
            startHour: 9
        ),
        TimelineEvent(
            title: "Design Sync",
            timeRange: "11:00 – 12:00",
            location: "Atelier 3",
            color: Color.purple,
            startHour: 11
        ),
        TimelineEvent(
            title: "Kunden Review",
            timeRange: "14:00 – 15:30",
            location: "Meetingraum 1",
            color: Color.orange,
            startHour: 14
        ),
        TimelineEvent(
            title: "Abend Workflow",
            timeRange: "17:30 – 18:30",
            location: "Remote",
            color: Color.green,
            startHour: 17
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    ZStack(alignment: .leading) {
                        timelineLine

                        VStack(spacing: 0) {
                            ForEach(hours, id: \.self) { hour in
                                timelineRow(for: hour)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Timeline Kalender")
                .font(.largeTitle.bold())
            Text("Heute · Mittwoch")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
    }

    private var timelineLine: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.25))
            .frame(width: 2)
            .offset(x: 38)
    }

    private func timelineRow(for hour: Int) -> some View {
        let event = events.first { $0.startHour == hour }

        return HStack(alignment: .top, spacing: 16) {
            timeLabel(for: hour)
                .frame(width: 60, alignment: .trailing)

            VStack(alignment: .leading, spacing: 12) {
                Circle()
                    .fill(event?.color ?? Color.gray.opacity(0.4))
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .padding(.top, 6)

                if let event {
                    eventCard(event)
                } else {
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 18)
    }

    private func timeLabel(for hour: Int) -> some View {
        Text(String(format: "%02d:00", hour))
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func eventCard(_ event: TimelineEvent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(event.title)
                .font(.headline)
                .foregroundStyle(.white)

            Text(event.timeRange)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))

            Text(event.location)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(event.color.gradient)
        )
        .shadow(color: event.color.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ContentView()
}
