//
//  AppTheme.swift
//  QuickFit
//

import SwiftUI

extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

struct AppTheme {
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(hex: "08080D"),
            Color(hex: "11111A"),
            Color(hex: "181523"),
            Color(hex: "24182D"),
            Color(hex: "31153A")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct AppBackgroundView: View {
    var body: some View {
        AppTheme.backgroundGradient
            .ignoresSafeArea()
    }
}
