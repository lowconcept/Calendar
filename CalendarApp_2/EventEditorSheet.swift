//
//  EventEditorSheet.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import SwiftUI
import SwiftData

struct EventEditorSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var event: CalendarEvent
    private let clampedToDay: Date?

    @State private var title: String
    @State private var start: Date
    @State private var end: Date
    @State private var colorHex: String

    init(event: CalendarEvent, clampedToDay: Date? = nil) {
        self.event = event
        self.clampedToDay = clampedToDay
        _title = State(initialValue: event.title)
        _start = State(initialValue: event.start)
        _end = State(initialValue: event.end)
        _colorHex = State(initialValue: event.colorHex)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Event title", text: $title)
                }

                Section("Time") {
                    DatePicker("Start",
                               selection: $start,
                               displayedComponents: [.date, .hourAndMinute])
                    DatePicker("End",
                               selection: $end,
                               displayedComponents: [.date, .hourAndMinute])
                }

                Section("Color") {
                    colorRow("#22C55E", "Green")
                    colorRow("#3B82F6", "Blue")
                    colorRow("#EF4444", "Red")
                    colorRow("#A855F7", "Purple")
                    colorRow("#F59E0B", "Orange")
                }

                Section {
                    Button(role: .destructive) {
                        context.delete(event)
                        dismiss()
                    } label: {
                        Text("Delete Event")
                    }
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAndClose()
                    }
                }
            }
        }
    }

    // MARK: - Save

    private func saveAndClose() {
        var s = start
        var e = end

        if let day = clampedToDay {
            let cal = Calendar.current
            let dayStart = cal.startOfDay(for: day)
            let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!

            // Datum auf selben Tag „snappen“, Zeit übernehmen
            let sComp = cal.dateComponents([.hour, .minute], from: s)
            let eComp = cal.dateComponents([.hour, .minute], from: e)

            s = cal.date(bySettingHour: sComp.hour ?? 0,
                         minute: sComp.minute ?? 0,
                         second: 0,
                         of: dayStart) ?? dayStart

            e = cal.date(bySettingHour: eComp.hour ?? 0,
                         minute: eComp.minute ?? 0,
                         second: 0,
                         of: dayStart) ?? dayStart

            s = min(max(s, dayStart), dayEnd)
            e = min(max(e, dayStart), dayEnd)
        }

        if e <= s {
            e = s.addingTimeInterval(60)
        }

        event.title = title
        event.start = s
        event.end = e
        event.colorHex = colorHex

        dismiss()
    }

    // MARK: - Color row

    @ViewBuilder
    private func colorRow(_ hex: String, _ name: String) -> some View {
        Button {
            colorHex = hex
        } label: {
            HStack {
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 20, height: 20)

                Text(name)

                Spacer()

                if colorHex == hex {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)  // ✅ GEÄNDERT: .accent → .tint
                }
            }
        }
    }

}
