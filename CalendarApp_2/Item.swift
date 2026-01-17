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
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
