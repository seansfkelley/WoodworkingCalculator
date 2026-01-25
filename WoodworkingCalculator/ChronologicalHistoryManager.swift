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
    
    private let sychronizer: JsonlSynchronizer
    private let logger = Logger(subsystem: "WoodworkingCalculator", category: "ChronologicalHistoryManager")

    init(fileURL: URL) {
        sychronizer = JsonlSynchronizer(fileURL: fileURL)

        // Background this so we can get the show on the road.
        Task { [weak self] in
            await self?.loadAndMerge()
        }
    }
    
    func append(_ entry: T) {
        let historyEntry = HistoryEntry(data: entry)
        
        entries.append(historyEntry)

        Task { [sychronizer, logger] in
            do {
                try await sychronizer.append(historyEntry)
            } catch {
                logger.error("failed to append entry to disk: \(error.localizedDescription)")
            }
        }
    }
    
    func delete(ids: Set<UUID>) {
        entries.removeAll { ids.contains($0.id) }
        
        let snapshot = entries

        Task { [sychronizer, logger] in
            do {
                try await sychronizer.rewrite(snapshot)
            } catch {
                logger.error("failed to rewrite entries to disk: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadAndMerge() async {
        do {
            let loadedEntries: [HistoryEntry<T>] = try await sychronizer.read()

            if entries.isEmpty {
                entries = loadedEntries
            } else {
                entries = loadedEntries + entries
                try await sychronizer.rewrite(entries)
            }
        } catch {
            // That's fine, we'll just have an in-memory session only.
            logger.error("failed to load history from disk: \(error.localizedDescription)")
        }
    }
}

private actor JsonlSynchronizer {
    private let fileURL: URL
    private let logger = Logger(subsystem: "WoodworkingCalculator", category: "HistoryDiskWriter")

    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    func read<T: Codable>() throws -> [HistoryEntry<T>] {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch CocoaError.fileReadNoSuchFile {
            logger.info("history file does not exist yet, starting with empty history")
            return []
        }
        
        let lines = String(data: data, encoding: .utf8)?
            .split(separator: "\n", omittingEmptySubsequences: true) ?? []
        
        var entries: [HistoryEntry<T>] = []
        let decoder = JSONDecoder()
        
        for (index, line) in lines.enumerated() {
            guard let lineData = line.data(using: .utf8) else {
                logger.warning("failed to convert line \(index) to data, skipping")
                continue
            }
            
            do {
                let entry = try decoder.decode(HistoryEntry<T>.self, from: lineData)
                entries.append(entry)
            } catch {
                logger.warning("failed to decode line \(index): \(error.localizedDescription), skipping")
            }
        }
        
        logger.info("loaded \(entries.count) entries from disk")
        return entries
    }
    
    func append<T: Codable>(_ entry: HistoryEntry<T>) throws {
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
    
    func rewrite<T: Codable>(_ entries: [HistoryEntry<T>]) throws {
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
