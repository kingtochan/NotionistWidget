import Foundation

struct NotionService {
    enum ServiceError: Error {
        case invalidURL
        case invalidResponse
    }

    func fetchTimelineItems(token: String, databaseId: String, notionAPIVersion: String) async throws -> [TimelineItem] {
        guard let url = URL(string: "https://api.notion.com/v1/databases/\(databaseId)/query") else {
            throw ServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue(notionAPIVersion, forHTTPHeaderField: "Notion-Version")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(NotionQueryRequest(sorts: [NotionSort(timestamp: "created_time", direction: "ascending")]))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ServiceError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(NotionQueryResponse.self, from: data)
        return decoded.results.compactMap { page in
            guard
                let titleProperty = page.properties["Name"],
                case let .title(titleItems) = titleProperty,
                let firstTitle = titleItems.first?.plainText
            else {
                return nil
            }

            let itemDate: Date?
            if
                let dateProperty = page.properties["Date"],
                case let .date(dateObject) = dateProperty,
                let raw = dateObject?.start,
                let parsed = Self.parseNotionDate(raw)
            {
                itemDate = parsed
            } else {
                itemDate = nil
            }

            let status: String?
            if
                let statusProperty = page.properties["Status"],
                case let .select(selectObject) = statusProperty
            {
                status = selectObject?.name
            } else {
                status = nil
            }

            return TimelineItem(id: page.id, name: firstTitle, date: itemDate, status: status)
        }
        .sorted(by: Self.compareTimelineItems)
    }

    /// Dated rows first (chronological); undated rows last (by name).
    private static func compareTimelineItems(_ a: TimelineItem, _ b: TimelineItem) -> Bool {
        switch (a.date, b.date) {
        case let (d1?, d2?):
            return d1 < d2
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }

    /// Notion sends `start` as full ISO 8601 or as calendar date `yyyy-MM-dd`.
    /// Default `ISO8601DateFormatter()` rejects date-only strings and would become “today”.
    private static func parseNotionDate(_ raw: String) -> Date? {
        if let d = isoDateTimeFractional.date(from: raw) { return d }
        if let d = isoDateTime.date(from: raw) { return d }
        if let d = isoDateOnly.date(from: raw) { return d }
        let trimmed = String(raw.prefix(10))
        return calendarDayFormatter.date(from: trimmed)
    }

    private static let isoDateTimeFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoDateTime: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let isoDateOnly: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()

    private static let calendarDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

private struct NotionQueryRequest: Codable {
    let sorts: [NotionSort]
}

private struct NotionSort: Codable {
    let timestamp: String
    let direction: String
}

private struct NotionQueryResponse: Codable {
    let results: [NotionPage]
}

private struct NotionPage: Codable {
    let id: String
    let properties: [String: NotionProperty]
}

private enum NotionProperty: Codable {
    case title([NotionTitle])
    case date(NotionDate?)
    case select(NotionSelect?)
    case unsupported

    enum CodingKeys: String, CodingKey {
        case type
        case title
        case date
        case select
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "title":
            let titles = try container.decode([NotionTitle].self, forKey: .title)
            self = .title(titles)
        case "date":
            let date = try container.decodeIfPresent(NotionDate.self, forKey: .date)
            self = .date(date)
        case "select":
            let select = try container.decodeIfPresent(NotionSelect.self, forKey: .select)
            self = .select(select)
        default:
            self = .unsupported
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .title(let titles):
            try container.encode("title", forKey: .type)
            try container.encode(titles, forKey: .title)
        case .date(let date):
            try container.encode("date", forKey: .type)
            try container.encode(date, forKey: .date)
        case .select(let select):
            try container.encode("select", forKey: .type)
            try container.encode(select, forKey: .select)
        case .unsupported:
            try container.encode("unsupported", forKey: .type)
        }
    }
}

private struct NotionTitle: Codable {
    let plainText: String

    enum CodingKeys: String, CodingKey {
        case plainText = "plain_text"
    }
}

private struct NotionDate: Codable {
    let start: String?
}

private struct NotionSelect: Codable {
    let name: String?
}
