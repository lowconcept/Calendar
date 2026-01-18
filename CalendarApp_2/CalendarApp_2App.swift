//
//  CalendarApp_2App.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import SwiftUI
import SwiftData

@main
struct CalendarApp_2App: App {

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([CalendarEvent.self])

        let storeURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CalendarApp_2.store")

        let config = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // 1) Store löschen & neu erstellen
            try? FileManager.default.removeItem(at: storeURL)

            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                // 2) Fallback: in-memory, damit die App nicht crasht
                let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return try! ModelContainer(for: schema, configurations: [memory])
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            DayPagerView()
        }
        .modelContainer(sharedModelContainer)
    }
}
