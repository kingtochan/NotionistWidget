import Foundation
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

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

// Codable mirror used for JSON persistence
private struct WidgetConfigJSON: Codable {
    var notionToken: String
    var databaseId: String
    var apiVersion: String
    var widgetTitle: String
    var backgroundColor: String
    var textColor: String
    var maxItemsMedium: Int
    var maxItemsLarge: Int
    var listStyle: String
}

enum WidgetConfigLoader {
    /// Shared config file at a fixed path both the app and widget can access
    /// without relying on App Group sandboxing (required for ad-hoc signed builds).
    private static var configFileURL: URL {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".notionistwidget", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("config.json")
    }

    static func load() -> WidgetConfigFile {
        guard
            let data = try? Data(contentsOf: configFileURL),
            let json = try? JSONDecoder().decode(WidgetConfigJSON.self, from: data)
        else {
            return .fallback
        }
        return WidgetConfigFile(
            notion: .init(
                token:      json.notionToken,
                databaseId: json.databaseId,
                apiVersion: json.apiVersion
            ),
            widget: .init(
                title:           json.widgetTitle,
                backgroundColor: json.backgroundColor,
                textColor:       json.textColor,
                maxItemsMedium:  json.maxItemsMedium,
                maxItemsLarge:   json.maxItemsLarge,
                listStyle:       WidgetListStyle(rawValue: json.listStyle) ?? .bullet
            )
        )
    }

    static func save(_ config: WidgetConfigFile) {
        let url = configFileURL
        let json = WidgetConfigJSON(
            notionToken:     config.notion.token,
            databaseId:      config.notion.databaseId,
            apiVersion:      config.notion.apiVersion,
            widgetTitle:     config.widget.title,
            backgroundColor: config.widget.backgroundColor,
            textColor:       config.widget.textColor ?? "white",
            maxItemsMedium:  config.widget.maxItemsMedium,
            maxItemsLarge:   config.widget.maxItemsLarge,
            listStyle:       config.widget.listStyle.rawValue
        )
        if let data = try? JSONEncoder().encode(json) {
            try? data.write(to: url, options: .atomic)
        }
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

// MARK: - Fallback config

private extension WidgetConfigFile {
    static let fallback = WidgetConfigFile(
        notion: .init(token: "", databaseId: "", apiVersion: "2022-06-28"),
        widget: .init(
            title:           "Notionist Widget",
            backgroundColor: "darkGray",
            textColor:       "white",
            maxItemsMedium:  4,
            maxItemsLarge:   8,
            listStyle:       .bullet
        )
    )
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
