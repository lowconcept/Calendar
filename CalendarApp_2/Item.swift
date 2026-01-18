//
//  Item.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var title: String
    var notes: String
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool

    init(title: String, notes: String = "", startDate: Date, endDate: Date, isAllDay: Bool = false) {
        self.title = title
        self.notes = notes
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
    }
}
