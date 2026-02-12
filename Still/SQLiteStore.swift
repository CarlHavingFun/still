import Foundation
import SQLite3

final class SQLiteStore {
    private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    private let dbURL: URL
    private var db: OpaquePointer?

    init(databaseURL: URL? = nil) {
        if let databaseURL {
            self.dbURL = databaseURL
        } else {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            self.dbURL = documents.appendingPathComponent("still.sqlite3")
        }
        openDatabase()
        createTables()
    }

    deinit {
        sqlite3_close(db)
    }

    private func openDatabase() {
        if sqlite3_open(dbURL.path, &db) != SQLITE_OK {
            print("Failed to open database at \(dbURL.path)")
        }
    }

    private func createTables() {
        let createEvents = """
        CREATE TABLE IF NOT EXISTS events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp REAL NOT NULL,
            kind TEXT NOT NULL,
            text TEXT NOT NULL
        );
        """

        let createMemory = """
        CREATE TABLE IF NOT EXISTS memory_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            body TEXT NOT NULL,
            confidence REAL NOT NULL,
            ttl REAL,
            status TEXT NOT NULL
        );
        """

        let createProactivity = """
        CREATE TABLE IF NOT EXISTS proactivity_state (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            enabled INTEGER NOT NULL,
            last_sent REAL,
            ignored_streak INTEGER NOT NULL,
            silence_until REAL,
            quiet_start_minutes INTEGER NOT NULL,
            quiet_end_minutes INTEGER NOT NULL,
            last_open REAL
        );
        """

        execute(sql: createEvents)
        execute(sql: createMemory)
        execute(sql: createProactivity)

        let insertDefaults = """
        INSERT OR IGNORE INTO proactivity_state
        (id, enabled, ignored_streak, quiet_start_minutes, quiet_end_minutes)
        VALUES (1, 0, 0, 1380, 540);
        """
        execute(sql: insertDefaults)
    }

    private func execute(sql: String) {
        var errorMessage: UnsafeMutablePointer<Int8>?
        if sqlite3_exec(db, sql, nil, nil, &errorMessage) != SQLITE_OK {
            if let errorMessage = errorMessage {
                print("SQLite error: \(String(cString: errorMessage))")
                sqlite3_free(errorMessage)
            }
        }
    }

    @discardableResult
    func addEvent(kind: EventKind, text: String) -> Int64 {
        let sql = "INSERT INTO events (timestamp, kind, text) VALUES (?, ?, ?);"
        var statement: OpaquePointer?
        let timestamp = Date().timeIntervalSince1970
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, timestamp)
            sqlite3_bind_text(statement, 2, kind.rawValue, -1, sqliteTransient)
            sqlite3_bind_text(statement, 3, text, -1, sqliteTransient)

            if sqlite3_step(statement) == SQLITE_DONE {
                let id = sqlite3_last_insert_rowid(db)
                sqlite3_finalize(statement)
                return id
            }
        }
        sqlite3_finalize(statement)
        return -1
    }

    @discardableResult
    func addMemoryItem(category: MemoryCategory, body: String, confidence: Double, ttl: Date?) -> Int64 {
        let sql = "INSERT INTO memory_items (category, body, confidence, ttl, status) VALUES (?, ?, ?, ?, ?);"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, category.rawValue, -1, sqliteTransient)
            sqlite3_bind_text(statement, 2, body, -1, sqliteTransient)
            sqlite3_bind_double(statement, 3, confidence)
            if let ttl = ttl {
                sqlite3_bind_double(statement, 4, ttl.timeIntervalSince1970)
            } else {
                sqlite3_bind_null(statement, 4)
            }
            sqlite3_bind_text(statement, 5, "active", -1, sqliteTransient)

            if sqlite3_step(statement) == SQLITE_DONE {
                let id = sqlite3_last_insert_rowid(db)
                sqlite3_finalize(statement)
                return id
            }
        }
        sqlite3_finalize(statement)
        return -1
    }

    func fetchMemoryItems(category: MemoryCategory) -> [MemoryItem] {
        expirePassingItems()
        let sql = "SELECT id, category, body, confidence, ttl, status FROM memory_items WHERE category = ? AND status = 'active' ORDER BY id DESC;"
        var statement: OpaquePointer?
        var items: [MemoryItem] = []

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, category.rawValue, -1, sqliteTransient)
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                let categoryRaw = String(cString: sqlite3_column_text(statement, 1))
                let body = String(cString: sqlite3_column_text(statement, 2))
                let confidence = sqlite3_column_double(statement, 3)
                let ttlValue = sqlite3_column_type(statement, 4) == SQLITE_NULL ? nil : sqlite3_column_double(statement, 4)
                let status = String(cString: sqlite3_column_text(statement, 5))

                let ttlDate = ttlValue.map { Date(timeIntervalSince1970: $0) }
                let category = MemoryCategory(rawValue: categoryRaw) ?? category
                items.append(MemoryItem(id: id, category: category, body: body, confidence: confidence, ttl: ttlDate, status: status))
            }
        }
        sqlite3_finalize(statement)
        return items
    }

    func updateMemoryItem(id: Int64, body: String, category: MemoryCategory, ttl: Date?) {
        let sql = "UPDATE memory_items SET body = ?, category = ?, ttl = ? WHERE id = ?;"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, body, -1, sqliteTransient)
            sqlite3_bind_text(statement, 2, category.rawValue, -1, sqliteTransient)
            if let ttl = ttl {
                sqlite3_bind_double(statement, 3, ttl.timeIntervalSince1970)
            } else {
                sqlite3_bind_null(statement, 3)
            }
            sqlite3_bind_int64(statement, 4, id)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }

    func deleteMemoryItem(id: Int64) {
        let sql = "UPDATE memory_items SET status = 'deleted' WHERE id = ?;"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, id)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }

    private func expirePassingItems() {
        let now = Date().timeIntervalSince1970
        let sql = "UPDATE memory_items SET status = 'deleted' WHERE category = 'passing' AND status = 'active' AND ttl IS NOT NULL AND ttl < ?;"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, now)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }

    func fetchEvents() -> [Event] {
        let sql = "SELECT id, timestamp, kind, text FROM events ORDER BY id ASC;"
        var statement: OpaquePointer?
        var events: [Event] = []

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                let timestamp = sqlite3_column_double(statement, 1)
                let kindRaw = String(cString: sqlite3_column_text(statement, 2))
                let text = String(cString: sqlite3_column_text(statement, 3))
                let kind = EventKind(rawValue: kindRaw) ?? .userInput
                events.append(Event(id: id, timestamp: Date(timeIntervalSince1970: timestamp), kind: kind, text: text))
            }
        }
        sqlite3_finalize(statement)
        return events
    }

    func fetchProactivityState() -> ProactivityState {
        let sql = "SELECT enabled, last_sent, ignored_streak, silence_until, quiet_start_minutes, quiet_end_minutes, last_open FROM proactivity_state WHERE id = 1;"
        var statement: OpaquePointer?
        var state = ProactivityState(enabled: false, lastSent: nil, ignoredStreak: 0, silenceUntil: nil, quietStartMinutes: 1380, quietEndMinutes: 540, lastOpen: nil)

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                let enabled = sqlite3_column_int(statement, 0) == 1
                let lastSent = sqlite3_column_type(statement, 1) == SQLITE_NULL ? nil : sqlite3_column_double(statement, 1)
                let ignored = Int(sqlite3_column_int(statement, 2))
                let silence = sqlite3_column_type(statement, 3) == SQLITE_NULL ? nil : sqlite3_column_double(statement, 3)
                let quietStart = Int(sqlite3_column_int(statement, 4))
                let quietEnd = Int(sqlite3_column_int(statement, 5))
                let lastOpen = sqlite3_column_type(statement, 6) == SQLITE_NULL ? nil : sqlite3_column_double(statement, 6)

                state = ProactivityState(
                    enabled: enabled,
                    lastSent: lastSent.map { Date(timeIntervalSince1970: $0) },
                    ignoredStreak: ignored,
                    silenceUntil: silence.map { Date(timeIntervalSince1970: $0) },
                    quietStartMinutes: quietStart,
                    quietEndMinutes: quietEnd,
                    lastOpen: lastOpen.map { Date(timeIntervalSince1970: $0) }
                )
            }
        }
        sqlite3_finalize(statement)
        return state
    }

    func updateProactivityState(_ state: ProactivityState) {
        let sql = """
        UPDATE proactivity_state
        SET enabled = ?, last_sent = ?, ignored_streak = ?, silence_until = ?, quiet_start_minutes = ?, quiet_end_minutes = ?, last_open = ?
        WHERE id = 1;
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, state.enabled ? 1 : 0)
            if let lastSent = state.lastSent {
                sqlite3_bind_double(statement, 2, lastSent.timeIntervalSince1970)
            } else {
                sqlite3_bind_null(statement, 2)
            }
            sqlite3_bind_int(statement, 3, Int32(state.ignoredStreak))
            if let silenceUntil = state.silenceUntil {
                sqlite3_bind_double(statement, 4, silenceUntil.timeIntervalSince1970)
            } else {
                sqlite3_bind_null(statement, 4)
            }
            sqlite3_bind_int(statement, 5, Int32(state.quietStartMinutes))
            sqlite3_bind_int(statement, 6, Int32(state.quietEndMinutes))
            if let lastOpen = state.lastOpen {
                sqlite3_bind_double(statement, 7, lastOpen.timeIntervalSince1970)
            } else {
                sqlite3_bind_null(statement, 7)
            }
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }

    func resetAll() {
        execute(sql: "DELETE FROM events;")
        execute(sql: "DELETE FROM memory_items;")
        execute(sql: "UPDATE proactivity_state SET enabled = 0, last_sent = NULL, ignored_streak = 0, silence_until = NULL, quiet_start_minutes = 1380, quiet_end_minutes = 540, last_open = NULL WHERE id = 1;")
    }

    func exportSnapshot() -> ExportSnapshot {
        let events = fetchEvents().map { event in
            ExportEvent(id: event.id, timestamp: event.timestamp, kind: event.kind.rawValue, text: event.text)
        }
        let memory = (MemoryCategory.allCases.flatMap { fetchMemoryItems(category: $0) }).map { item in
            ExportMemoryItem(id: item.id, category: item.category.rawValue, body: item.body, confidence: item.confidence, ttl: item.ttl, status: item.status)
        }
        let state = fetchProactivityState()
        let proactivity = ExportProactivity(
            enabled: state.enabled,
            lastSent: state.lastSent,
            ignoredStreak: state.ignoredStreak,
            silenceUntil: state.silenceUntil,
            quietStartMinutes: state.quietStartMinutes,
            quietEndMinutes: state.quietEndMinutes
        )

        return ExportSnapshot(exportedAt: Date(), events: events, memory: memory, proactivity: proactivity)
    }

    func replaceAll(with snapshot: ExportSnapshot) throws {
        execute(sql: "BEGIN TRANSACTION;")
        do {
            resetAll()
            try importEvents(snapshot.events)
            try importMemory(snapshot.memory)
            try importProactivity(snapshot.proactivity)
            execute(sql: "COMMIT;")
        } catch {
            execute(sql: "ROLLBACK;")
            throw error
        }
    }

    private func importEvents(_ events: [ExportEvent]) throws {
        let sql = "INSERT INTO events (id, timestamp, kind, text) VALUES (?, ?, ?, ?);"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteImportError.prepareFailed("events insert prepare failed")
        }
        defer { sqlite3_finalize(statement) }

        for event in events {
            sqlite3_reset(statement)
            sqlite3_clear_bindings(statement)
            sqlite3_bind_int64(statement, 1, event.id)
            sqlite3_bind_double(statement, 2, event.timestamp.timeIntervalSince1970)
            sqlite3_bind_text(statement, 3, event.kind, -1, sqliteTransient)
            sqlite3_bind_text(statement, 4, event.text, -1, sqliteTransient)
            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw SQLiteImportError.stepFailed("events insert failed")
            }
        }
    }

    private func importMemory(_ items: [ExportMemoryItem]) throws {
        let sql = "INSERT INTO memory_items (id, category, body, confidence, ttl, status) VALUES (?, ?, ?, ?, ?, ?);"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteImportError.prepareFailed("memory insert prepare failed")
        }
        defer { sqlite3_finalize(statement) }

        for item in items {
            sqlite3_reset(statement)
            sqlite3_clear_bindings(statement)
            sqlite3_bind_int64(statement, 1, item.id)
            sqlite3_bind_text(statement, 2, item.category, -1, sqliteTransient)
            sqlite3_bind_text(statement, 3, item.body, -1, sqliteTransient)
            sqlite3_bind_double(statement, 4, item.confidence)
            if let ttl = item.ttl {
                sqlite3_bind_double(statement, 5, ttl.timeIntervalSince1970)
            } else {
                sqlite3_bind_null(statement, 5)
            }
            sqlite3_bind_text(statement, 6, item.status, -1, sqliteTransient)
            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw SQLiteImportError.stepFailed("memory insert failed")
            }
        }
    }

    private func importProactivity(_ state: ExportProactivity) throws {
        let sql = """
        UPDATE proactivity_state
        SET enabled = ?, last_sent = ?, ignored_streak = ?, silence_until = ?, quiet_start_minutes = ?, quiet_end_minutes = ?, last_open = NULL
        WHERE id = 1;
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteImportError.prepareFailed("proactivity update prepare failed")
        }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_int(statement, 1, state.enabled ? 1 : 0)
        if let lastSent = state.lastSent {
            sqlite3_bind_double(statement, 2, lastSent.timeIntervalSince1970)
        } else {
            sqlite3_bind_null(statement, 2)
        }
        sqlite3_bind_int(statement, 3, Int32(state.ignoredStreak))
        if let silenceUntil = state.silenceUntil {
            sqlite3_bind_double(statement, 4, silenceUntil.timeIntervalSince1970)
        } else {
            sqlite3_bind_null(statement, 4)
        }
        sqlite3_bind_int(statement, 5, Int32(state.quietStartMinutes))
        sqlite3_bind_int(statement, 6, Int32(state.quietEndMinutes))
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw SQLiteImportError.stepFailed("proactivity update failed")
        }
    }
}

enum SQLiteImportError: Error {
    case prepareFailed(String)
    case stepFailed(String)
}
