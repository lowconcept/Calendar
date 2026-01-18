//
//  Collection+Safe.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 17.01.26.
//

import Foundation

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
