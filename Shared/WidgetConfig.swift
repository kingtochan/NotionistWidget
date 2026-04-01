import Foundation
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

let appGroupID = "group.com.example.notionistwidget"

enum WidgetListStyle: String, Codable, CaseIterable {
    case bullet
    case numbered
}

struct WidgetConfigFile {
    struct Notion {
        var token: String
        var databaseId: String
        var apiVersion: String
    }

    struct WidgetDisplay {
        var title: String
        var backgroundColor: String
        var textColor: String?
        var maxItemsMedium: Int
        var maxItemsLarge: Int
        var listStyle: WidgetListStyle
    }

    var notion: Notion
    var widget: WidgetDisplay
}

enum WidgetConfigLoader {
    private enum Keys {
        static let notionToken      = "notionToken"
        static let databaseId       = "databaseId"
        static let apiVersion       = "apiVersion"
        static let widgetTitle      = "widgetTitle"
        static let backgroundColor  = "backgroundColor"
        static let textColor        = "textColor"
        static let maxItemsMedium   = "maxItemsMedium"
        static let maxItemsLarge    = "maxItemsLarge"
        static let listStyle        = "listStyle"
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func load() -> WidgetConfigFile {
        let ud = defaults
        let notion = WidgetConfigFile.Notion(
            token:      ud.string(forKey: Keys.notionToken)  ?? "",
            databaseId: ud.string(forKey: Keys.databaseId)   ?? "",
            apiVersion: ud.string(forKey: Keys.apiVersion)   ?? "2022-06-28"
        )
        let widget = WidgetConfigFile.WidgetDisplay(
            title:           ud.string(forKey: Keys.widgetTitle)     ?? "Notionist Widget",
            backgroundColor: ud.string(forKey: Keys.backgroundColor) ?? "darkGray",
            textColor:       ud.string(forKey: Keys.textColor)       ?? "white",
            maxItemsMedium:  ud.object(forKey: Keys.maxItemsMedium)  as? Int ?? 4,
            maxItemsLarge:   ud.object(forKey: Keys.maxItemsLarge)   as? Int ?? 8,
            listStyle:       WidgetListStyle(rawValue: ud.string(forKey: Keys.listStyle) ?? "bullet") ?? .bullet
        )
        return WidgetConfigFile(notion: notion, widget: widget)
    }

    static func save(_ config: WidgetConfigFile) {
        let ud = defaults
        ud.set(config.notion.token,             forKey: Keys.notionToken)
        ud.set(config.notion.databaseId,        forKey: Keys.databaseId)
        ud.set(config.notion.apiVersion,        forKey: Keys.apiVersion)
        ud.set(config.widget.title,             forKey: Keys.widgetTitle)
        ud.set(config.widget.backgroundColor,   forKey: Keys.backgroundColor)
        ud.set(config.widget.textColor,         forKey: Keys.textColor)
        ud.set(config.widget.maxItemsMedium,    forKey: Keys.maxItemsMedium)
        ud.set(config.widget.maxItemsLarge,     forKey: Keys.maxItemsLarge)
        ud.set(config.widget.listStyle.rawValue, forKey: Keys.listStyle)
    }

    static func backgroundColor(from value: String) -> Color {
        if let c = Color(colorName: value) { return c }
        if let c = Color(hex: value) { return c }
        #if canImport(AppKit)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color.gray.opacity(0.2)
        #endif
    }

    static func textColor(from value: String?) -> Color {
        guard let value else { return .primary }
        if let c = Color(colorName: value) { return c }
        if let c = Color(hex: value) { return c }
        return .primary
    }
}

// MARK: - Color helpers

extension Color {
    init?(colorName: String) {
        switch colorName.lowercased().trimmingCharacters(in: .whitespaces) {
        case "black":                self = .black
        case "white":                self = .white
        case "red":                  self = .red
        case "green":                self = .green
        case "blue":                 self = .blue
        case "orange":               self = .orange
        case "yellow":               self = .yellow
        case "pink":                 self = .pink
        case "purple":               self = .purple
        case "cyan":                 self = .cyan
        case "mint":                 self = .mint
        case "teal":                 self = .teal
        case "indigo":               self = .indigo
        case "brown":                self = .brown
        case "gray", "grey":         self = .gray
        case "darkgray", "darkgrey": self = Color(red: 0.11, green: 0.11, blue: 0.12)
        case "lightgray", "lightgrey": self = Color(red: 0.92, green: 0.92, blue: 0.94)
        default: return nil
        }
    }

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
            g = Double((value & 0x0000_FF00) >> 8)  / 255
            b = Double(value  & 0x0000_00FF)         / 255
        } else {
            a = 1
            r = Double((value & 0xFF0000) >> 16) / 255
            g = Double((value & 0x00FF00) >> 8)  / 255
            b = Double(value  & 0x0000FF)         / 255
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
