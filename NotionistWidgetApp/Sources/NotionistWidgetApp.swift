import SwiftUI
import WidgetKit

@main
struct NotionistWidgetApp: App {
    var body: some Scene {
        WindowGroup("Notionist Widget Settings") {
            SettingsView()
        }
        .defaultSize(width: 540, height: 560)
    }
}

struct SettingsView: View {
    // Notion
    @State private var token        = ""
    @State private var databaseId   = ""
    @State private var apiVersion   = "2022-06-28"

    // Widget display
    @State private var widgetTitle      = "Notionist Widget"
    @State private var backgroundColor  = "darkGray"
    @State private var textColor        = "white"
    @State private var maxItemsMedium   = 4
    @State private var maxItemsLarge    = 8
    @State private var listStyle        = WidgetListStyle.bullet

    @State private var savedFeedback = false

    var body: some View {
        Form {
            // MARK: Notion credentials
            Section {
                LabeledContent("Integration Token") {
                    TextField("secret_xxxxxxxxxxxx", text: $token)
                        .textFieldStyle(.roundedBorder)
                        .labelsHidden()
                }
                LabeledContent("Database ID") {
                    TextField("32-character ID from the Notion URL", text: $databaseId)
                        .textFieldStyle(.roundedBorder)
                        .labelsHidden()
                }
                LabeledContent("API Version") {
                    TextField("2022-06-28", text: $apiVersion)
                        .textFieldStyle(.roundedBorder)
                        .labelsHidden()
                        .frame(maxWidth: 140)
                }
            } header: {
                Text("Notion").font(.headline)
            }

            // MARK: Widget display
            Section {
                LabeledContent("Widget Title") {
                    TextField("Notionist Widget", text: $widgetTitle)
                        .textFieldStyle(.roundedBorder)
                        .labelsHidden()
                }

                colorRow(label: "Background Color",
                         hint: "e.g. darkGray or #1C1C1E",
                         value: $backgroundColor,
                         preview: WidgetConfigLoader.backgroundColor(from: backgroundColor))

                colorRow(label: "Text Color",
                         hint: "e.g. white or #FFFFFF",
                         value: $textColor,
                         preview: WidgetConfigLoader.textColor(from: textColor))

                LabeledContent("Max Items — Medium") {
                    Stepper("\(maxItemsMedium)", value: $maxItemsMedium, in: 1...10)
                }
                LabeledContent("Max Items — Large") {
                    Stepper("\(maxItemsLarge)", value: $maxItemsLarge, in: 1...20)
                }

                LabeledContent("List Style") {
                    Picker("", selection: $listStyle) {
                        ForEach(WidgetListStyle.allCases, id: \.self) { style in
                            Text(style.rawValue.capitalized).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: 180)
                }
            } header: {
                Text("Widget Display").font(.headline)
            } footer: {
                Text("Color accepts a name (black, white, red, green, blue, orange, yellow, pink, purple, cyan, mint, teal, indigo, brown, gray, darkGray, lightGray) or a hex code (#RRGGBB).")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            // MARK: Actions
            Section {
                HStack(spacing: 16) {
                    Button("Save & Reload Widget") {
                        saveAndReload()
                    }
                    .buttonStyle(.borderedProminent)

                    if savedFeedback {
                        Label("Saved!", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .transition(.opacity)
                    }

                    Spacer()

                    Button("Reload Widget") {
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .formStyle(.grouped)
        .padding(.vertical, 8)
        .onAppear(perform: loadSettings)
    }

    // MARK: - Color row helper

    @ViewBuilder
    private func colorRow(label: String, hint: String, value: Binding<String>, preview: Color) -> some View {
        LabeledContent(label) {
            HStack(spacing: 8) {
                TextField(hint, text: value)
                    .textFieldStyle(.roundedBorder)
                RoundedRectangle(cornerRadius: 5)
                    .fill(preview)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.primary.opacity(0.15)))
                    .frame(width: 28, height: 22)
            }
        }
    }

    // MARK: - Persistence

    private func loadSettings() {
        let cfg = WidgetConfigLoader.load()
        token           = cfg.notion.token
        databaseId      = cfg.notion.databaseId
        apiVersion      = cfg.notion.apiVersion
        widgetTitle     = cfg.widget.title
        backgroundColor = cfg.widget.backgroundColor
        textColor       = cfg.widget.textColor ?? "white"
        maxItemsMedium  = cfg.widget.maxItemsMedium
        maxItemsLarge   = cfg.widget.maxItemsLarge
        listStyle       = cfg.widget.listStyle
    }

    private func saveAndReload() {
        let cfg = WidgetConfigFile(
            notion: .init(
                token:      token.trimmingCharacters(in: .whitespaces),
                databaseId: databaseId.trimmingCharacters(in: .whitespaces),
                apiVersion: apiVersion.trimmingCharacters(in: .whitespaces)
            ),
            widget: .init(
                title:           widgetTitle,
                backgroundColor: backgroundColor,
                textColor:       textColor,
                maxItemsMedium:  maxItemsMedium,
                maxItemsLarge:   maxItemsLarge,
                listStyle:       listStyle
            )
        )
        WidgetConfigLoader.save(cfg)
        WidgetCenter.shared.reloadAllTimelines()

        withAnimation {
            savedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { savedFeedback = false }
        }
    }
}
