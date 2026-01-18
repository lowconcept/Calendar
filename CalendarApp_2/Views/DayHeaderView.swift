//
//  DayHeaderView.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import SwiftUI

struct DayHeaderView: View {
    let date: Date
    let onToday: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(date.weekdayDisplay)
                .font(.headline)
                .foregroundStyle(.secondary)
            HStack(alignment: .lastTextBaseline) {
                Text(date.longDateDisplay)
                    .font(.largeTitle.bold())
                Spacer()
                Button(action: onToday) {
                    Text("Today")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    DayHeaderView(date: .now, onToday: {})
}
