//
//  Models.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 18.01.26.
//

import Foundation
import SwiftData

@Model
final class CalendarEvent {

    var title: String
    var start: Date
    var end: Date
    var colorHex: String

    init(
        title: String,
        start: Date,
        end: Date,
        colorHex: String = "#22C55E"
    ) {
        self.title = title
        self.start = start
        self.end = end
        self.colorHex = colorHex
    }

    /// Sicheres Ende: mindestens 1 Minute nach Start
    var safeEnd: Date {
        max(end, start.addingTimeInterval(60))
    }
}
