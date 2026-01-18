//
//  DebugTools.swift
//  CalendarApp_2
//
//  Production-safe Debug UI (only compiled in DEBUG)
//

import SwiftUI

#if DEBUG
enum DebugUI {
    /// Master switch
    static let enabled: Bool = true

    /// Shows green outline (selected) / subtle outline (unselected)
    static let showEventOutlines: Bool = true

    /// Shows event ID pills on each event (prefix(6))
    static let showEventIDs: Bool = false

    /// Shows handle hit areas (yellow) to debug visibility/touch
    static let showHandleHitAreas: Bool = false
}

struct DebugHUD: View {
    let activeID: UUID?
    let isInteracting: Bool
    let isCreating: Bool
    let scrollOffsetY: CGFloat
    let eventCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("activeID: \(activeID?.uuidString.prefix(6) ?? \"nil\")")
            Text("interacting: \(isInteracting ? \"1\" : \"0\")   creating: \(isCreating ? \"1\" : \"0\")")
            Text(String(format: "scrollY: %.0f", scrollOffsetY))
            Text("events: \(eventCount)")
        }
        .font(.system(size: 12, weight: .semibold, design: .monospaced))
        .padding(10)
        .background(.black.opacity(0.72))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
        .padding(12)
    }
}
#endif  DEBUG
