import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var keptItems: [MemoryItem] = []
    @Published private(set) var heldItems: [MemoryItem] = []
    @Published private(set) var passingItems: [MemoryItem] = []
    @Published private(set) var proactivityState: ProactivityState

    let store: SQLiteStore
    private let proactivityManager: ProactivityManager

    init() {
        self.store = SQLiteStore()
        self.proactivityManager = ProactivityManager()
        self.proactivityState = store.fetchProactivityState()
        loadMemory()
        proactivityManager.updateSchedule(for: proactivityState)
    }

    func loadMemory() {
        keptItems = store.fetchMemoryItems(category: .kept)
        heldItems = store.fetchMemoryItems(category: .held)
        passingItems = store.fetchMemoryItems(category: .passing)
    }

    func addInput(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.addEvent(kind: .userInput, text: trimmed)
        store.addMemoryItem(category: .held, body: trimmed, confidence: 1.0, ttl: nil)
        loadMemory()
    }

    func updateMemoryItem(_ item: MemoryItem, body: String, category: MemoryCategory) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let ttl: Date?
        if category == .passing {
            ttl = Date().addingTimeInterval(24 * 60 * 60)
        } else {
            ttl = nil
        }
        store.updateMemoryItem(id: item.id, body: trimmed, category: category, ttl: ttl)
        loadMemory()
    }

    func deleteMemoryItem(_ item: MemoryItem) {
        store.deleteMemoryItem(id: item.id)
        loadMemory()
    }

    func setProactivityEnabled(_ enabled: Bool) {
        if enabled {
            proactivityManager.requestAuthorizationIfNeeded { [weak self] granted in
                guard let self = self else { return }
                Task { @MainActor in
                    var state = self.proactivityState
                    state.enabled = granted
                    self.persistProactivity(state)
                }
            }
        } else {
            var state = proactivityState
            state.enabled = false
            state.ignoredStreak = 0
            state.silenceUntil = nil
            persistProactivity(state)
        }
    }

    func setQuietHours(startMinutes: Int, endMinutes: Int) {
        var state = proactivityState
        state.quietStartMinutes = startMinutes
        state.quietEndMinutes = endMinutes
        persistProactivity(state)
    }

    func appDidBecomeActive() {
        var state = proactivityState
        let now = Date()

        if state.enabled {
            let lastScheduled = ProactivityManager.lastScheduledDate(now: now, quietStart: state.quietStartMinutes, quietEnd: state.quietEndMinutes)
            if state.lastSent == nil || lastScheduled > (state.lastSent ?? .distantPast) {
                if let lastOpen = state.lastOpen, lastOpen < lastScheduled {
                    state.ignoredStreak += 1
                } else {
                    state.ignoredStreak = 0
                }
                state.lastSent = lastScheduled
            }

            if state.ignoredStreak >= 2 {
                state.silenceUntil = now.addingTimeInterval(72 * 60 * 60)
            }

            if let silenceUntil = state.silenceUntil, silenceUntil <= now {
                state.silenceUntil = nil
                state.ignoredStreak = 0
            }
        }

        state.lastOpen = now
        persistProactivity(state)
    }

    func exportSnapshot() -> URL? {
        let snapshot = store.exportSnapshot()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(snapshot)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("still-export-\(Int(Date().timeIntervalSince1970)).json")
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Export failed: \(error)")
            return nil
        }
    }

    func importSnapshot(from url: URL) -> Bool {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let data = try Data(contentsOf: url)
            let snapshot = try decoder.decode(ExportSnapshot.self, from: data)
            try store.replaceAll(with: snapshot)
            loadMemory()
            proactivityState = store.fetchProactivityState()
            proactivityManager.updateSchedule(for: proactivityState)
            return true
        } catch {
            print("Import failed: \(error)")
            return false
        }
    }

    func deleteAll() {
        store.resetAll()
        loadMemory()
        proactivityState = store.fetchProactivityState()
        proactivityManager.updateSchedule(for: proactivityState)
    }

    private func persistProactivity(_ state: ProactivityState) {
        store.updateProactivityState(state)
        proactivityState = state
        proactivityManager.updateSchedule(for: state)
    }
}
