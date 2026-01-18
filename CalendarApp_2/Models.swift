//
//  Models.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class CalendarEventEntity {
    var id: UUID
    var title: String
    var start: Date
    var end: Date
    var colorHex: String

    init(id: UUID = UUID(), title: String, start: Date, end: Date, colorHex: String) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.colorHex = colorHex
    }
}

struct ColorPreset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let hex: String
}

enum CalendarConstants {
    static let hourHeight: CGFloat = 72
    static let minuteHeight: CGFloat = hourHeight / 60
    static let timelinePaddingLeading: CGFloat = 64
    static let gridLineOpacity: CGFloat = 0.16
    static let snapMinutes: Int = 5
    static let minEventMinutes: Int = 10
    static let defaultEventMinutes: Int = 60
}
