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
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(date, format: .dateTime.weekday(.wide))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))

                    Text(date, format: .dateTime.day().month(.wide).year())
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }

                Spacer()

                Button("Today", action: onToday)
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.10))
                    .clipShape(Capsule())
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Divider()
                .overlay(.white.opacity(0.08))
                .padding(.horizontal, 16)
        }
        .padding(.bottom, 10)
        .background(
            Color.black
                .overlay(Color.white.opacity(0.06))
                .ignoresSafeArea(edges: .top)
        )
    }
}
