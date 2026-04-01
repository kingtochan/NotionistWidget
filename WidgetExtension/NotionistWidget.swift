import WidgetKit
import SwiftUI

struct NotionistEntry: TimelineEntry {
    let date: Date
    let items: [TimelineItem]
    let errorMessage: String?
    let title: String
    let background: Color
    let textColor: Color
    let listStyle: WidgetListStyle
}

struct NotionistProvider: TimelineProvider {
    /// Keeps items with no date, or dated today (local) or later; preserves service sort order.
    private static func upcomingItemsForDisplay(
        _ items: [TimelineItem],
        family: WidgetFamily,
        limits: WidgetConfigFile.WidgetDisplay
    ) -> [TimelineItem] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let limit: Int = {
            switch family {
            case .systemLarge:
                return max(1, limits.maxItemsLarge)
            default:
                return max(1, limits.maxItemsMedium)
            }
        }()
        return items
            .filter { item in
                guard let d = item.date else { return true }
                return d >= startOfToday
            }
            .prefix(limit)
            .map { $0 }
    }

    func placeholder(in context: Context) -> NotionistEntry {
        let cfg = WidgetConfigLoader.load()
        let bg = WidgetConfigLoader.backgroundColor(from: cfg.widget.backgroundColor)
        let fg = WidgetConfigLoader.textColor(from: cfg.widget.textColor)
        return NotionistEntry(
            date: Date(),
            items: [
                TimelineItem(id: "1", name: "Milestone Alpha", date: Date().addingTimeInterval(86400), status: "In Progress"),
                TimelineItem(id: "2", name: "Launch Beta", date: Date().addingTimeInterval(172800), status: "Planned")
            ],
            errorMessage: nil,
            title: cfg.widget.title,
            background: bg,
            textColor: fg,
            listStyle: cfg.widget.listStyle
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NotionistEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NotionistEntry>) -> Void) {
        Task {
            let cfg = WidgetConfigLoader.load()
            let w = cfg.widget
            let bg = WidgetConfigLoader.backgroundColor(from: w.backgroundColor)
            let fg = WidgetConfigLoader.textColor(from: w.textColor)
            let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)

            let n = cfg.notion
            let credsMissing =
                n.token.isEmpty || n.databaseId.isEmpty
                || n.token == "YOUR_NOTION_TOKEN_HERE"
                || n.databaseId == "YOUR_DATABASE_ID_HERE"

            let timeline: Timeline<NotionistEntry>
            if credsMissing {
                let entry = NotionistEntry(
                    date: Date(),
                    items: [],
                    errorMessage: "Edit Shared/WidgetConfig.json with your Notion token and database ID, then rebuild.",
                    title: w.title,
                    background: bg,
                    textColor: fg,
                    listStyle: w.listStyle
                )
                timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
            } else {
                do {
                    let items = try await NotionService().fetchTimelineItems(
                        token: n.token,
                        databaseId: n.databaseId,
                        notionAPIVersion: n.apiVersion
                    )
                    let shown = Self.upcomingItemsForDisplay(items, family: context.family, limits: w)
                    let entry = NotionistEntry(
                        date: Date(),
                        items: shown,
                        errorMessage: nil,
                        title: w.title,
                        background: bg,
                        textColor: fg,
                        listStyle: w.listStyle
                    )
                    timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
                } catch {
                    let entry = NotionistEntry(
                        date: Date(),
                        items: [],
                        errorMessage: "Failed to load Notion data.",
                        title: w.title,
                        background: bg,
                        textColor: fg,
                        listStyle: w.listStyle
                    )
                    timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
                }
            }

            await MainActor.run {
                completion(timeline)
            }
        }
    }
}

struct NotionistWidgetView: View {
    var entry: NotionistProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.title)
                .font(.headline)
                .foregroundStyle(entry.textColor)

            if let errorMessage = entry.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(entry.textColor.opacity(0.6))
            } else if entry.items.isEmpty {
                Text("No upcoming items.")
                    .font(.caption)
                    .foregroundStyle(entry.textColor.opacity(0.6))
            } else {
                ForEach(Array(entry.items.enumerated()), id: \.element.id) { index, item in
                    HStack(alignment: .top, spacing: 8) {
                        listMarker(index: index)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.subheadline)
                                .lineLimit(1)
                                .foregroundStyle(entry.textColor)
                            Text(subtitle(for: item))
                                .font(.caption2)
                                .foregroundStyle(entry.textColor.opacity(0.6))
                        }
                    }
                }
            }
        }
        .padding(12)
    }

    @ViewBuilder
    private func listMarker(index: Int) -> some View {
        switch entry.listStyle {
        case .numbered:
            Text("\(index + 1).")
                .font(.caption.weight(.medium))
                .foregroundStyle(entry.textColor.opacity(0.6))
                .frame(minWidth: 20, alignment: .trailing)
                .padding(.top, 2)
        case .bullet:
            Circle()
                .foregroundStyle(entry.textColor)
                .frame(width: 7, height: 7)
                .padding(.top, 6)
        }
    }

    private func subtitle(for item: TimelineItem) -> String {
        let datePart: String
        if let d = item.date {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            datePart = formatter.string(from: d)
        } else {
            datePart = "No date"
        }
        if let status = item.status {
            return "\(datePart) — \(status)"
        }
        return datePart
    }
}

struct NotionistWidget: Widget {
    let kind = "NotionistWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NotionistProvider()) { entry in
            NotionistWidgetView(entry: entry)
                .containerBackground(entry.background, for: .widget)
        }
        .configurationDisplayName("Notionist Widget")
        .description("Shows upcoming items from a Notion database.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

@main
struct NotionistWidgetBundle: WidgetBundle {
    var body: some Widget {
        NotionistWidget()
    }
}
