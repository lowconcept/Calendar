//
//  DayPagerView.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import SwiftUI

struct DayPagerView: View {
    private let calendar = Calendar.current
    private let daySpan = 21

    @State private var selectedIndex: Int = 0

    private var days: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (-daySpan...daySpan).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
    }

    private var todayIndex: Int {
        daySpan
    }

    private var selectedDate: Date {
        days[safe: selectedIndex] ?? calendar.startOfDay(for: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            DayHeaderView(date: selectedDate, onToday: jumpToToday)
            TabView(selection: $selectedIndex) {
                ForEach(days.indices, id: \.self) { index in
                    DayTimelineView(day: days[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .onAppear {
            selectedIndex = todayIndex
        }
    }

    private func jumpToToday() {
        withAnimation(.easeInOut) {
            selectedIndex = todayIndex
        }
    }
}

#Preview {
    DayPagerView()
        .modelContainer(for: CalendarEvent.self, inMemory: true)
}
