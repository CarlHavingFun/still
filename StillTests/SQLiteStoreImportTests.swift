import XCTest
@testable import Still

final class SQLiteStoreImportTests: XCTestCase {
    func testMoveItemToPassingUpdatesCategoryAndTTL() throws {
        let dbURL = temporaryURL(named: "move-to-passing")
        defer { try? FileManager.default.removeItem(at: dbURL) }

        let store = SQLiteStore(databaseURL: dbURL)
        let id = store.addMemoryItem(category: .held, body: "Keep this for now", confidence: 1.0, ttl: nil)
        let ttl = Date().addingTimeInterval(3600)

        store.updateMemoryItem(id: id, body: "Keep this for now", category: .passing, ttl: ttl)

        let held = store.fetchMemoryItems(category: .held)
        XCTAssertFalse(held.contains(where: { $0.id == id }))

        let passing = store.fetchMemoryItems(category: .passing)
        let moved = passing.first(where: { $0.id == id })
        XCTAssertNotNil(moved)
        XCTAssertEqual(moved?.category, .passing)
        XCTAssertNotNil(moved?.ttl)
    }

    func testExportImportRoundTrip() throws {
        let sourceURL = temporaryURL(named: "source")
        let targetURL = temporaryURL(named: "target")

        defer {
            try? FileManager.default.removeItem(at: sourceURL)
            try? FileManager.default.removeItem(at: targetURL)
        }

        let source = SQLiteStore(databaseURL: sourceURL)
        _ = source.addEvent(kind: .userInput, text: "I am not ready yet")
        _ = source.addMemoryItem(category: .held, body: "I am not ready yet", confidence: 1.0, ttl: nil)
        _ = source.addMemoryItem(category: .passing, body: "This week only", confidence: 0.6, ttl: Date().addingTimeInterval(86400))

        let proactivity = ProactivityState(
            enabled: true,
            lastSent: Date(),
            ignoredStreak: 1,
            silenceUntil: Date().addingTimeInterval(3600),
            quietStartMinutes: 1320,
            quietEndMinutes: 420,
            lastOpen: nil
        )
        source.updateProactivityState(proactivity)

        let snapshot = source.exportSnapshot()

        let target = SQLiteStore(databaseURL: targetURL)
        XCTAssertNoThrow(try target.replaceAll(with: snapshot))

        let importedEvents = target.fetchEvents()
        XCTAssertEqual(importedEvents.count, 1)
        XCTAssertEqual(importedEvents.first?.text, "I am not ready yet")

        let importedHeld = target.fetchMemoryItems(category: .held)
        XCTAssertEqual(importedHeld.count, 1)

        let importedPassing = target.fetchMemoryItems(category: .passing)
        XCTAssertEqual(importedPassing.count, 1)

        let importedState = target.fetchProactivityState()
        XCTAssertTrue(importedState.enabled)
        XCTAssertEqual(importedState.ignoredStreak, 1)
        XCTAssertEqual(importedState.quietStartMinutes, 1320)
        XCTAssertEqual(importedState.quietEndMinutes, 420)
    }

    private func temporaryURL(named name: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("still-tests-\(name)-\(UUID().uuidString)")
            .appendingPathExtension("sqlite3")
    }
}
