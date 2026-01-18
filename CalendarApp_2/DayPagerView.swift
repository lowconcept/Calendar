//
//  DayPagerView.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import SwiftUI

struct DayPagerView: View {
    @State private var selectedDay = Calendar.current.startOfDay(for: Date())
    @State private var showDebugOverlay = false
    @State private var scrollToTodayTrigger = UUID()

    private let calendar = Calendar.current
    private let pageRange = -30...30

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                CalendarHeaderView(date: selectedDay) {
                    selectedDay = calendar.startOfDay(for: Date())
                    scrollToTodayTrigger = UUID()
                }
                .padding(.horizontal, 20)

                TabView(selection: $selectedDay) {
                    ForEach(pageRange, id: \.self) { offset in
                        let date = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: Date())) ?? Date()
                        DayTimelineView(day: date, showDebugOverlay: $showDebugOverlay, scrollToTodayTrigger: scrollToTodayTrigger)
                            .tag(calendar.startOfDay(for: date))
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .padding(.top, 24)

            DebugOverlayToggle(isOn: $showDebugOverlay)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    DayPagerView()
}
