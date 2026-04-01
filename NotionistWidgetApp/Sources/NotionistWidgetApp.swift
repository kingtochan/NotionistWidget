import SwiftUI
import WidgetKit

@main
struct NotionistWidgetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Notionist Widget")
                .font(.title2.bold())
            Text("Edit Shared/WidgetConfig.json (Notion token, database ID, colors, list style, item counts). Rebuild the app, then use Reload if the widget looks stale.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Reload widgets") {
                WidgetCenter.shared.reloadAllTimelines()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(minWidth: 420, minHeight: 180)
    }
}
