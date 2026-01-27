import Foundation
import Observation
import OSLog

struct HistoryEntry<T: Codable>: Codable, Identifiable, Timestamped {
    let id: UUID
    let timestamp: Date
    let data: T
    
    init(data: T, timestamp: Date = Date()) {
        self.id = UUID()
        self.timestamp = timestamp
        self.data = data
    }
}

@Observable
final class ChronologicalHistoryManager<T: Codable> {
    private(set) var entries: [HistoryEntry<T>] = []
    private let synchronizer: JsonlSynchronizer<HistoryEntry<T>>

    init(fileURL: URL) {
        synchronizer = JsonlSynchronizer(fileURL: fileURL)
        Task {
            entries = synchronizer.loadAndMerge(self.entries)
        }
    }
    
    func append(_ entry: T) {
        let historyEntry = HistoryEntry(data: entry)
        entries.append(historyEntry)
        synchronizer.append(historyEntry)
    }
    
    func delete(ids: Set<UUID>) {
        entries.removeAll { ids.contains($0.id) }
        let snapshot = entries
        synchronizer.rewrite(snapshot)
    }
}

private final class JsonlSynchronizer<T: Codable & Timestamped> {
    private let fileURL: URL
    private let logger = Logger(subsystem: "WoodworkingCalculator", category: "JsonlSynchronizer")
    private let operationQueue = DispatchQueue(label: "com.woodworkingcalculator.history.synchronizer", qos: .utility)

    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    func loadAndMerge(_ getCurrentEntries: @escaping @autoclosure () -> [T]) -> [T] {
        do {
            let allPersistedEntries: [T] = try _read()

            let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date.distantPast
            let recentEntries = allPersistedEntries.filter { $0.timestamp >= oneYearAgo }

            var entries = getCurrentEntries()
            let needsRewrite = !entries.isEmpty || recentEntries.count != allPersistedEntries.count

            entries = recentEntries + entries
            if needsRewrite {
                rewrite(entries)
            }
            return entries
        } catch {
            // That's fine, we'll just have an in-memory session only.
            logger.error("failed to load history from disk: \(error.localizedDescription)")
            return getCurrentEntries()
        }
    }

    func append(_ entry: T) {
        operationQueue.async { [weak self] in
            guard let self else { return }
            do {
                try self._append(entry)
            } catch {
                self.logger.error("failed to append entry to disk: \(error.localizedDescription)")
            }
        }
    }
    
    func rewrite(_ entries: [T]) {
        operationQueue.async { [weak self] in
            guard let self else { return }
            do {
                try self._rewrite(entries)
            } catch {
                self.logger.error("failed to rewrite entries to disk: \(error.localizedDescription)")
            }
        }
    }
    
    private func _read() throws -> [T] {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch CocoaError.fileReadNoSuchFile {
            logger.info("history file does not exist yet, starting with empty history")
            return []
        }
        
        let lines = String(data: data, encoding: .utf8)?
            .split(separator: "\n", omittingEmptySubsequences: true) ?? []
        
        var entries: [T] = []
        let decoder = JSONDecoder()
        
        for (index, line) in lines.enumerated() {
            guard let lineData = line.data(using: .utf8) else {
                logger.warning("failed to convert line \(index) to data, skipping")
                continue
            }
            
            do {
                let entry = try decoder.decode(T.self, from: lineData)
                entries.append(entry)
            } catch {
                logger.warning("failed to decode line \(index): \(error.localizedDescription), skipping")
            }
        }
        
        logger.info("loaded \(entries.count) entries from disk")
        return entries
    }
    
    private func _append(_ entry: T) throws {
        let encoder = JSONEncoder()
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        let lineData = try encoder.encode(entry) + Data("\n".utf8)
        
        do {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            defer { try? fileHandle.close() }
            try fileHandle.seekToEnd()
            try fileHandle.write(contentsOf: lineData)
        } catch CocoaError.fileNoSuchFile {
            try lineData.write(to: fileURL)
        }
        
        logger.debug("appended entry to disk")
    }
    
    private func _rewrite(_ entries: [T]) throws {
        let encoder = JSONEncoder()
        
        var fileData = Data()
        for entry in entries {
            let entryData = try encoder.encode(entry)
            fileData.append(entryData)
            fileData.append(contentsOf: "\n".utf8)
        }
        
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        try fileData.write(to: fileURL, options: .atomic)
        
        logger.info("rewrote history file with \(entries.count) entries")
    }
}
