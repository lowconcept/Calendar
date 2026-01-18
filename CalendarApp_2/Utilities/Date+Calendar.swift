//
//  Date+Calendar.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import Foundation

extension Calendar {
    func startOfDay(for date: Date, in timeZone: TimeZone = .current) -> Date {
        var calendar = self
        calendar.timeZone = timeZone
        return calendar.startOfDay(for: date)
    }

    func endOfDay(for date: Date, in timeZone: TimeZone = .current) -> Date {
        let start = startOfDay(for: date, in: timeZone)
        return date(byAdding: .day, value: 1, to: start) ?? start
    }
}

extension Date {
    var weekdayDisplay: String {
        formatted(Date.FormatStyle().weekday(.wide))
    }

    var longDateDisplay: String {
        formatted(Date.FormatStyle().day().month(.wide).year())
    }
}
