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
    let subtitle: String
    let start: String
    let end: String
    let color: Color
}

struct ContentView: View {
    private let hours = Array(7...20)
    private let events: [Int: TimelineEvent] = [
        8: TimelineEvent(
            title: "Morgensync",
            subtitle: "Teamraum A",
            start: "08:30",
            end: "09:15",
            color: Color.indigo
        ),
        10: TimelineEvent(
            title: "Produkt Review",
            subtitle: "Workshop",
            start: "10:00",
            end: "11:00",
            color: Color.pink
        ),
        13: TimelineEvent(
            title: "Kunden Call",
            subtitle: "Remote",
            start: "13:30",
            end: "14:00",
            color: Color.orange
        ),
        16: TimelineEvent(
            title: "Design Focus",
            subtitle: "Studio B",
            start: "16:00",
            end: "18:00",
            color: Color.green
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    VStack(spacing: 0) {
                        ForEach(hours, id: \.self) { hour in
                            timelineRow(hour: hour, event: events[hour])
                        }
                    }
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Timeline Kalender")
                .font(.largeTitle.bold())

            HStack(spacing: 12) {
                Label("Mittwoch, 17. Januar", systemImage: "calendar")
                Text("4 Events")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
        }
    }

    private func timelineRow(hour: Int, event: TimelineEvent?) -> some View {
        HStack(alignment: .top, spacing: 16) {
            timelineTime(hour)
                .frame(width: 64, alignment: .trailing)

            VStack(alignment: .leading, spacing: 12) {
                timelineMarker(isActive: event != nil, color: event?.color ?? .gray)

                if let event {
                    eventCard(event)
                } else {
                    Divider()
                        .background(Color.gray.opacity(0.15))
                        .padding(.leading, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 18)
    }

    private func timelineTime(_ hour: Int) -> some View {
        Text(String(format: "%02d:00", hour))
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func timelineMarker(isActive: Bool, color: Color) -> some View {
        Circle()
            .fill(isActive ? color : Color.gray.opacity(0.3))
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .background(
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 2)
                    .offset(y: 20)
            )
            .padding(.top, 2)
    }

    private func eventCard(_ event: TimelineEvent) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(event.title)
                .font(.headline)
                .foregroundStyle(.white)

            Text(event.subtitle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))

            HStack(spacing: 8) {
                Image(systemName: "clock")
                Text("\(event.start) – \(event.end)")
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.white.opacity(0.85))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(event.color.gradient)
        )
        .shadow(color: event.color.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ContentView()
}
