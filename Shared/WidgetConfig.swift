import Foundation
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

enum WidgetListStyle: String, Codable {
    case bullet
    case numbered
}

struct WidgetConfigFile: Codable {
    struct Notion: Codable {
        var token: String
        var databaseId: String
        var apiVersion: String
    }

    struct WidgetDisplay: Codable {
        var title: String
        var backgroundColorHex: String
        var maxItemsMedium: Int
        var maxItemsLarge: Int
        var listStyle: WidgetListStyle
    }

    var notion: Notion
    var widget: WidgetDisplay
}

enum WidgetConfigLoader {
    private static let resourceName = "WidgetConfig"

    static func load() -> WidgetConfigFile {
        guard
            let url = Bundle.main.url(forResource: resourceName, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode(WidgetConfigFile.self, from: data)
        else {
            return .fallback
        }
        return decoded
    }

    static func backgroundColor(from hex: String) -> Color {
        if let c = Color(hex: hex) { return c }
        #if canImport(AppKit)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color.gray.opacity(0.2)
        #endif
    }
}

private extension WidgetConfigFile {
    static let fallback = WidgetConfigFile(
        notion: .init(token: "", databaseId: "", apiVersion: "2022-06-28"),
        widget: WidgetDisplay(
            title: "Notionist Widget",
            backgroundColorHex: "#EBEBF0",
            maxItemsMedium: 4,
            maxItemsLarge: 8,
            listStyle: .bullet
        )
    )
}

private extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6 || s.count == 8 else { return nil }

        var value: UInt64 = 0
        guard Scanner(string: s).scanHexInt64(&value) else { return nil }

        let a, r, g, b: Double
        if s.count == 8 {
            a = Double((value & 0xFF00_0000) >> 24) / 255
            r = Double((value & 0x00FF_0000) >> 16) / 255
            g = Double((value & 0x0000_FF00) >> 8) / 255
            b = Double(value & 0x0000_00FF) / 255
        } else {
            a = 1
            r = Double((value & 0xFF0000) >> 16) / 255
            g = Double((value & 0x00FF00) >> 8) / 255
            b = Double(value & 0x0000FF) / 255
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
