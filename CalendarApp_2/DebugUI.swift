//
//  DebugUI.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import SwiftUI

struct DebugOverlayToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Toggle("Debug", isOn: $isOn)
                    .toggleStyle(.switch)
                    .tint(.green)
                    .labelsHidden()
                    .padding(8)
                    .background(.black.opacity(0.6), in: Capsule())
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .allowsHitTesting(true)
    }
}

struct DebugOverlayView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(.white)
            .padding(6)
            .background(Color.blue.opacity(0.6), in: RoundedRectangle(cornerRadius: 6))
    }
}

