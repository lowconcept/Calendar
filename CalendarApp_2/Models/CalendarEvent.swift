//
//  CalendarEvent.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import Foundation
import SwiftData

@Model
final class CalendarEvent {
    var title: String
    var startDate: Date
    var endDate: Date
    var notes: String?

    init(title: String, startDate: Date, endDate: Date, notes: String? = nil) {
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
    }
}
