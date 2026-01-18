//
//  Color+Hex.swift
//  CalendarApp_2
//
//  Created by Florian Springfeldt on 18.01.26.
//

import SwiftUI

extension Color {
    init(hex: String) {
        var string = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if string.hasPrefix("#") {
            string.removeFirst()
        }

        // ungerade Stellen verdoppeln letzte Ziffer (z.B. "fff" -> "ffff")
        if !string.count.isMultiple(of: 2), let last = string.last {
            string.append(last)
        }

        // max. 8 Stellen (RGBA)
        if string.count > 8 {
            string = String(string.prefix(8))
        }

        var color: UInt64 = 0
        Scanner(string: string).scanHexInt64(&color)

        switch string.count {
        case 2:
            // Grau
            let g = Double(Int(color) & 0xFF) / 255.0
            self.init(.sRGB, red: g, green: g, blue: g, opacity: 1)

        case 4:
            // Grau + Alpha
            let g = Double(Int(color >> 8) & 0xFF) / 255.0
            let a = Double(Int(color) & 0xFF) / 255.0
            self.init(.sRGB, red: g, green: g, blue: g, opacity: a)

        case 6:
            // RGB
            let r = Double(Int(color >> 16) & 0xFF) / 255.0
            let g = Double(Int(color >> 8) & 0xFF) / 255.0
            let b = Double(Int(color) & 0xFF) / 255.0
            self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)

        case 8:
            // RGBA
            let r = Double(Int(color >> 24) & 0xFF) / 255.0
            let g = Double(Int(color >> 16) & 0xFF) / 255.0
            let b = Double(Int(color >> 8) & 0xFF) / 255.0
            let a = Double(Int(color) & 0xFF) / 255.0
            self.init(.sRGB, red: r, green: g, blue: b, opacity: a)

        default:
            self.init(.sRGB, red: 1, green: 1, blue: 1, opacity: 1)
        }
    }
}
