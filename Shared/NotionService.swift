import Foundation

struct NotionService {
    enum ServiceError: LocalizedError {
        case invalidURL
        case invalidResponse(statusCode: Int, message: String?)
        case invalidResponsePayload

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "The Notion database ID is invalid."
            case let .invalidResponse(statusCode, message):
                let trimmed = message?.trimmingCharacters(in: .whitespacesAndNewlines)
                if let trimmed, !trimmed.isEmpty {
                    return "Notion returned \(statusCode): \(trimmed)"
                }
                return "Notion returned HTTP \(statusCode)."
            case .invalidResponsePayload:
                return "The Notion response could not be read."
            }
        }
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

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponsePayload
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let apiError = try? JSONDecoder().decode(NotionAPIError.self, from: data)
            let fallbackMessage = String(data: data, encoding: .utf8)
            throw ServiceError.invalidResponse(
                statusCode: httpResponse.statusCode,
                message: apiError?.message ?? fallbackMessage
            )
        }

        let decoded = try JSONDecoder().decode(NotionQueryResponse.self, from: data)
        return decoded.results.compactMap { page in
            let title = page.properties.preferredTitleText() ?? "Untitled"

            let itemDate: Date?
            if
                let raw = page.properties.preferredDateStart(),
                let parsed = Self.parseNotionDate(raw)
            {
                itemDate = parsed
            } else {
                itemDate = nil
            }

            let status = page.properties.preferredStatusName()

            return TimelineItem(id: page.id, name: title, date: itemDate, status: status)
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

private struct NotionAPIError: Codable {
    let code: String?
    let message: String?
}

private struct NotionPage: Codable {
    let id: String
    let properties: [String: NotionProperty]
}

private enum NotionProperty: Codable {
    case title([NotionTitle])
    case date(NotionDate?)
    case select(NotionSelect?)
    case status(NotionSelect?)
    case unsupported

    enum CodingKeys: String, CodingKey {
        case type
        case title
        case date
        case select
        case status
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
        case "status":
            let status = try container.decodeIfPresent(NotionSelect.self, forKey: .status)
            self = .status(status)
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
        case .status(let status):
            try container.encode("status", forKey: .type)
            try container.encode(status, forKey: .status)
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

private extension NotionProperty {
    var titleText: String? {
        guard case let .title(titleItems) = self else { return nil }
        let joined = titleItems
            .map(\.plainText)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return joined.isEmpty ? nil : joined
    }

    var dateStart: String? {
        guard case let .date(dateObject) = self else { return nil }
        return dateObject?.start?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var statusName: String? {
        switch self {
        case let .select(select):
            return select?.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        case let .status(status):
            return status?.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        default:
            return nil
        }
    }

    var isTitle: Bool {
        if case .title = self {
            return true
        }
        return false
    }

    var isDate: Bool {
        if case .date = self {
            return true
        }
        return false
    }

    var isStatusLike: Bool {
        switch self {
        case .select, .status:
            return true
        default:
            return false
        }
    }
}

private extension Dictionary where Key == String, Value == NotionProperty {
    func preferredTitleText() -> String? {
        if let exact = self["Name"]?.titleText {
            return exact
        }

        return values
            .first(where: \.isTitle)?
            .titleText
    }

    func preferredDateStart() -> String? {
        if let exact = self["Date"]?.dateStart, !exact.isEmpty {
            return exact
        }

        return values
            .first(where: \.isDate)?
            .dateStart
    }

    func preferredStatusName() -> String? {
        if let exact = self["Status"]?.statusName, !exact.isEmpty {
            return exact
        }

        return values
            .first(where: \.isStatusLike)?
            .statusName
    }
}
