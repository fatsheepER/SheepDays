//
//  Color+SheepDays.swift
//  SheepDays
//
//  Created by 王飞扬 on 2025/5/8.
//

import SwiftUI

struct ColorComponent: Codable {
    let red: Float
    let green: Float
    let blue: Float

    var color: Color {
        Color(red: Double(red), green: Double(green), blue: Double(blue))
    }

    static func fromColor(_ color: Color) -> ColorComponent {
        let resolved = color.resolve(in: EnvironmentValues())
        return ColorComponent(
            red: resolved.red,
            green: resolved.green,
            blue: resolved.blue
        )
    }
}

extension Color {
    // create color from rbga-string
    init (rgba: String) {
        let indexes = rgba.split(separator: ",").compactMap { Double($0) }
        guard indexes.count == 4 else {
            self = .black
            return
        }
        self = Color(
            .sRGB,
            red: indexes[0] / 255.0,
            green: indexes[1] / 255.0,
            blue: indexes[2] / 255.0,
            opacity: indexes[3] / 100.0
        )
    }
    
    // get a SwiftUI.Color's rgba-string
    var rgba: String? {
        guard let cgColor = UIColor(self).cgColor.components, cgColor.count >= 4 else {
            return nil
        }
        let red: Double = cgColor[0] * 255.0
        let green: Double = cgColor[1] * 255.0
        let blue: Double = cgColor[2] * 255.0
        let opacity: Double = cgColor[3] * 100.0
        return "\(red),\(green),\(blue),\(opacity)"
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0

        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0

        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
}

extension Color {
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if a != Float(1.0) {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}
