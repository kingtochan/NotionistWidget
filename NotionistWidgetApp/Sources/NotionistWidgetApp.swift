import SwiftUI
import WidgetKit
#if canImport(AppKit)
import AppKit
#endif

@main
struct NotionistWidgetApp: App {
    var body: some Scene {
        WindowGroup("Notionist Widget") {
            SetupView()
        }
        .defaultSize(width: 620, height: 540)
    }
}

struct SetupView: View {
    private let config = WidgetConfigLoader.load()
    @State private var copiedExample = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notionist Widget")
                        .font(.largeTitle.bold())
                    Text("This app is the container for the widget. Configure `widget-config.json`, build from Xcode, launch the built app once, then add the widget from macOS.")
                        .foregroundStyle(.secondary)
                }

                GroupBox("Bundled Configuration") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("These values are from the config bundled into this build of the app.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        configRow("Widget Title", value: config.widget.title)
                        configRow("Database ID", value: maskedValue(config.notion.databaseId))
                        configRow("API Version", value: config.notion.apiVersion)
                        configRow("Background Color", value: config.widget.backgroundColor)
                        configRow("Text Color", value: config.widget.textColor ?? "white")
                        configRow("Medium Items", value: "\(config.widget.maxItemsMedium)")
                        configRow("Large Items", value: "\(config.widget.maxItemsLarge)")
                        configRow("List Style", value: config.widget.listStyle.rawValue)
                        configRow("Token", value: maskedValue(config.notion.token))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("How To Update") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("1. Edit `Config/widget-config.json` in the project.")
                        Text("2. Put in your Notion token, database ID, and display options.")
                        Text("3. Open the project in Xcode and leave signing as `Sign to Run Locally`.")
                        Text("4. Build and run the `NotionistWidgetApp` target once.")
                        Text("5. Move the built app to `/Applications` and launch it once from there.")
                        Text("6. Add or refresh the widget on your desktop.")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Widget Registration") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("No Apple Developer team is required for the default local build flow.")
                        Text("This project is configured for Xcode's local `Sign to Run Locally` signing.")
                        Text("For the widget to appear in Edit Widgets, use the Xcode-built app and launch it once from `/Applications` after copying it there.")
                        Text("A compile-only build made with `CODE_SIGNING_ALLOWED=NO` is useful for verification, but macOS may not register its widget extension for the gallery.")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 12) {
                    Button("Reload Widget") {
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Copy Template JSON") {
                        copyExampleJSON()
                    }
                    .buttonStyle(.bordered)

                    if copiedExample {
                        Text("Copied")
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(24)
        }
    }

    @ViewBuilder
    private func configRow(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func copyExampleJSON() {
        guard let example = WidgetConfigLoader.exampleJSONTemplate() else { return }
        #if canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(example, forType: .string)
        #endif
        copiedExample = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copiedExample = false
        }
    }

    private func displayValue(_ value: String) -> String {
        value.isEmpty ? "Not set" : value
    }

    private func maskedValue(_ value: String) -> String {
        guard !value.isEmpty else { return "Not set" }
        guard value.count > 8 else { return String(repeating: "•", count: value.count) }
        return "\(value.prefix(4))••••\(value.suffix(4))"
    }
}
