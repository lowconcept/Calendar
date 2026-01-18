//
//  ContentView.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.startDate) private var items: [Item]

    @State private var selection: Item?
    @State private var isPresentingEditor = false
    @State private var editingItem: Item?

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                if items.isEmpty {
                    ContentUnavailableView("Keine Termine", systemImage: "calendar", description: Text("Erstelle deinen ersten Termin mit +."))
                } else {
                    ForEach(items) { item in
                        NavigationLink(value: item) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                Text(dateRangeText(for: item))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .navigationTitle("Kalender")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editingItem = nil
                        isPresentingEditor = true
                    } label: {
                        Label("Add Event", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let selectedItem = selection {
                EventDetailView(item: selectedItem) {
                    editingItem = selectedItem
                    isPresentingEditor = true
                }
            } else {
                ContentUnavailableView("Wähle einen Termin", systemImage: "calendar")
            }
        }
        .sheet(isPresented: $isPresentingEditor) {
            EventEditor(item: editingItem)
        }
    }

    private func dateRangeText(for item: Item) -> String {
        let formatter = Date.FormatStyle(date: .abbreviated, time: item.isAllDay ? .omitted : .shortened)
        let startText = item.startDate.formatted(formatter)
        let endText = item.endDate.formatted(formatter)
        if Calendar.current.isDate(item.startDate, inSameDayAs: item.endDate) {
            return item.isAllDay ? startText : "\(startText) – \(item.endDate.formatted(Date.FormatStyle(time: .shortened)))"
        }
        return "\(startText) – \(endText)"
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

private struct EventDetailView: View {
    let item: Item
    let onEdit: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(item.title)
                    .font(.largeTitle)
                    .bold()

                VStack(alignment: .leading, spacing: 8) {
                    Label(dateRangeText(for: item), systemImage: "calendar")
                        .foregroundStyle(.secondary)
                    if !item.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(item.notes)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Bearbeiten", action: onEdit)
            }
        }
    }

    private func dateRangeText(for item: Item) -> String {
        let formatter = Date.FormatStyle(date: .long, time: item.isAllDay ? .omitted : .shortened)
        let startText = item.startDate.formatted(formatter)
        let endText = item.endDate.formatted(formatter)
        if Calendar.current.isDate(item.startDate, inSameDayAs: item.endDate) {
            return item.isAllDay ? startText : "\(startText) – \(item.endDate.formatted(Date.FormatStyle(time: .shortened)))"
        }
        return "\(startText) – \(endText)"
    }
}

private struct EventEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let item: Item?
    @State private var title: String
    @State private var notes: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isAllDay: Bool

    init(item: Item?) {
        self.item = item
        _title = State(initialValue: item?.title ?? "")
        _notes = State(initialValue: item?.notes ?? "")
        let now = Date()
        _startDate = State(initialValue: item?.startDate ?? now)
        _endDate = State(initialValue: item?.endDate ?? Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now)
        _isAllDay = State(initialValue: item?.isAllDay ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Titel") {
                    TextField("Terminname", text: $title)
                }

                Section("Zeit") {
                    Toggle("Ganztägig", isOn: $isAllDay)
                    DatePicker("Beginn", selection: $startDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                        .onChange(of: startDate) { newValue in
                            if endDate < newValue {
                                endDate = newValue
                            }
                        }
                    DatePicker("Ende", selection: $endDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                }

                Section("Notizen") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle(item == nil ? "Neuer Termin" : "Termin bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        save()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedEndDate = max(endDate, startDate)

        if let item {
            item.title = trimmedTitle
            item.notes = notes
            item.startDate = startDate
            item.endDate = sanitizedEndDate
            item.isAllDay = isAllDay
        } else {
            let newItem = Item(title: trimmedTitle, notes: notes, startDate: startDate, endDate: sanitizedEndDate, isAllDay: isAllDay)
            modelContext.insert(newItem)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
