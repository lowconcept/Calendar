//
//  CalendarHeaderView.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import SwiftUI

struct CalendarHeaderView: View {
    let date: Date
    let onToday: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(date.formatted(.dateTime.weekday(.abbreviated)) + " " + date.formatted(.dateTime.day()))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(date.formatted(.dateTime.month(.abbreviated).year()))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Button("Today") {
                onToday()
            }
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.white.opacity(0.2), in: Capsule())
        }
    }
}

