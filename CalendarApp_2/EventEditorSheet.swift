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
    @Environment(\.modelContext) private var modelContext

    @Bindable var event: CalendarEventEntity
    let presets: [ColorPreset]

    @State private var workingTitle: String
    @State private var workingStart: Date
    @State private var workingEnd: Date
    @State private var workingColor: String

    init(event: CalendarEventEntity, presets: [ColorPreset]) {
        self._event = Bindable(wrappedValue: event)
        self.presets = presets
        _workingTitle = State(initialValue: event.title)
        _workingStart = State(initialValue: event.start)
        _workingEnd = State(initialValue: event.end)
        _workingColor = State(initialValue: event.colorHex)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Title", text: $workingTitle)
                }

                Section("Time") {
                    DatePicker("Start", selection: $workingStart, displayedComponents: [.date, .hourAndMinute])
                        .onChange(of: workingStart) { _, newValue in
                            let clamped = clampToDay(date: newValue, day: event.start)
                            workingStart = clamped
                            if workingEnd <= workingStart {
                                workingEnd = calendar.date(byAdding: .minute, value: CalendarConstants.defaultEventMinutes, to: workingStart) ?? workingStart
                            }
                        }
                    DatePicker("End", selection: $workingEnd, displayedComponents: [.date, .hourAndMinute])
                        .onChange(of: workingEnd) { _, newValue in
                            let clamped = clampToDay(date: newValue, day: event.start)
                            workingEnd = max(clamped, calendar.date(byAdding: .minute, value: CalendarConstants.minEventMinutes, to: workingStart) ?? workingStart)
                        }
                }

                Section("Color") {
                    HStack(spacing: 12) {
                        ForEach(presets) { preset in
                            Circle()
                                .fill(Color(hex: preset.hex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: workingColor == preset.hex ? 3 : 0)
                                )
                                .onTapGesture {
                                    workingColor = preset.hex
                                }
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section {
                    Button(role: .destructive) {
                        modelContext.delete(event)
                        dismiss()
                    } label: {
                        Text("Delete Event")
                    }
                }
            }
            .navigationTitle("Edit Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        event.title = workingTitle.isEmpty ? "Untitled Event" : workingTitle
                        event.start = workingStart
                        event.end = workingEnd
                        event.colorHex = workingColor
                        dismiss()
                    }
                }
            }
        }
    }

    private let calendar = Calendar.current

    private func clampToDay(date: Date, day: Date) -> Date {
        let startOfDay = calendar.startOfDay(for: day)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        return min(max(date, startOfDay), endOfDay.addingTimeInterval(-60))
    }
}

