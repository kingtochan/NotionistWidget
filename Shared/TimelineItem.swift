import Foundation

struct TimelineItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    /// `nil` if the Notion **Date** property is missing, empty, or unparseable.
    let date: Date?
    let status: String?
}
