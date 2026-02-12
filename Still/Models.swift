import Foundation

enum EventKind: String {
    case userInput = "user_input"
    case stillReply = "still_reply"
    case proactive = "proactive"
}

enum MemoryCategory: String, CaseIterable, Identifiable {
    case kept
    case held
    case passing

    var id: String { rawValue }

    func title(for language: AppLanguage) -> String {
        switch (self, language) {
        case (.kept, .english): return "Kept"
        case (.kept, .chinese): return "已留存"
        case (.held, .english): return "Held"
        case (.held, .chinese): return "暂存"
        case (.passing, .english): return "Passing"
        case (.passing, .chinese): return "短暂"
        }
    }
}

struct Event: Identifiable {
    let id: Int64
    let timestamp: Date
    let kind: EventKind
    let text: String
}

struct MemoryItem: Identifiable, Equatable {
    let id: Int64
    var category: MemoryCategory
    var body: String
    var confidence: Double
    var ttl: Date?
    var status: String
}

struct ProactivityState: Equatable {
    var enabled: Bool
    var lastSent: Date?
    var ignoredStreak: Int
    var silenceUntil: Date?
    var quietStartMinutes: Int
    var quietEndMinutes: Int
    var lastOpen: Date?
}

struct ExportSnapshot: Codable {
    let exportedAt: Date
    let events: [ExportEvent]
    let memory: [ExportMemoryItem]
    let proactivity: ExportProactivity
}

struct ExportEvent: Codable {
    let id: Int64
    let timestamp: Date
    let kind: String
    let text: String
}

struct ExportMemoryItem: Codable {
    let id: Int64
    let category: String
    let body: String
    let confidence: Double
    let ttl: Date?
    let status: String
}

struct ExportProactivity: Codable {
    let enabled: Bool
    let lastSent: Date?
    let ignoredStreak: Int
    let silenceUntil: Date?
    let quietStartMinutes: Int
    let quietEndMinutes: Int
}
