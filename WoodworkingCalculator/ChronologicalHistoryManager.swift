//
//  ChronologicalHistoryManager.swift
//
//  A generic, file-backed history management subsystem optimized for frequent
//  appends and list operations with infrequent deletions.
//
//  Created on January 23, 2026.
//

import Foundation
import Observation
import OSLog

// MARK: - History Entry

/// Generic wrapper for history entries
/// The wrapper provides its own ID and timestamp, so the payload only needs to be Codable
struct HistoryEntry<T: Codable>: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let data: T
    
    init(data: T, timestamp: Date = Date()) {
        self.id = UUID()
        self.timestamp = timestamp
        self.data = data
    }
}

// MARK: - Chronological History Manager

/// A generic, file-backed history management system
///
/// Features:
/// - Generic support for any `Codable` type
/// - Optimized for frequent appends and list operations
/// - JSON Lines (`.jsonl`) file format for efficient appends
/// - In-memory cache as source of truth
/// - Background disk I/O via stateless actor
/// - Non-blocking initialization with background merge
/// - Observable for SwiftUI integration
@Observable
final class ChronologicalHistoryManager<Entry: Codable> {
    
    // MARK: - Properties
    
    /// Internal storage in chronological order (oldest first)
    private var _entries: [HistoryEntry<Entry>] = []
    
    /// All entries in reverse-chronological order (latest first)
    /// Observable - SwiftUI views automatically update when this changes
    var entries: [HistoryEntry<Entry>] {
        _entries.reversed()
    }
    
    /// Stateless actor for disk I/O operations
    private let diskIO: DiskIOActor
    
    /// Logger for error reporting
    private let logger = Logger(subsystem: "ChronologicalHistoryManager", category: "History")
    
    // MARK: - Initialization
    
    /// Initialize with a file URL
    /// Returns immediately with empty state. Loads existing history from disk asynchronously.
    /// When disk load completes, merges with any new entries added in the meantime.
    /// - Parameter fileURL: Location of the JSON-lines history file
    init(fileURL: URL) {
        self.diskIO = DiskIOActor(fileURL: fileURL)
        
        // Start loading in the background
        Task { [weak self] in
            await self?.loadAndMerge()
        }
    }
    
    // MARK: - Public API
    
    /// Append a new entry with the current timestamp
    /// Updates in-memory state immediately. Disk write happens asynchronously in the background.
    /// - Parameter entry: The entry to append
    func append(_ entry: Entry) {
        let historyEntry = HistoryEntry(data: entry)
        
        // Update memory immediately (O(1) amortized)
        _entries.append(historyEntry)
        
        // Persist to disk in background (fire-and-forget)
        Task { [diskIO, logger] in
            do {
                try await diskIO.append(historyEntry)
            } catch {
                logger.error("Failed to append entry to disk: \(error.localizedDescription)")
            }
        }
    }
    
    /// Delete entries by their IDs
    /// Updates in-memory state immediately. Disk rewrite happens asynchronously in the background.
    /// - Parameter ids: Set of IDs to delete
    func delete(ids: Set<UUID>) {
        // Update memory immediately (O(n) for filtering)
        _entries.removeAll { ids.contains($0.id) }
        
        // Create snapshot for background persistence
        let snapshot = _entries
        
        // Persist to disk in background (fire-and-forget)
        Task { [diskIO, logger] in
            do {
                try await diskIO.rewrite(snapshot)
            } catch {
                logger.error("Failed to rewrite entries to disk: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Load entries from disk and merge with any entries added during load
    private func loadAndMerge() async {
        do {
            // Read from disk (entries already in chronological order)
            let loadedEntries: [HistoryEntry<Entry>] = try await diskIO.read()

            // Check if entries were added during load
            if _entries.isEmpty {
                // No merge needed - just set entries directly
                _entries = loadedEntries
            } else {
                // Merge needed: loaded entries (older) + current entries (newer)
                let mergedEntries = loadedEntries + _entries
                _entries = mergedEntries
                
                // Persist merged state back to disk
                try await diskIO.rewrite(mergedEntries)
            }
        } catch {
            // If load fails, continue with empty state (memory is authoritative)
            logger.error("Failed to load history from disk: \(error.localizedDescription)")
        }
    }
}

// MARK: - Disk I/O Actor

/// Stateless actor that handles disk I/O operations
/// Provides three commands: read, append, and rewrite
private actor DiskIOActor {
    
    // MARK: - Properties
    
    private let fileURL: URL
    private let logger = Logger(subsystem: "ChronologicalHistoryManager", category: "DiskIO")
    
    // MARK: - Initialization
    
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    // MARK: - Commands
    
    /// Command 1: Read entire file, return array of entries
    func read<T: Codable>() throws -> [HistoryEntry<T>] {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            logger.info("History file does not exist yet, starting with empty history")
            return []
        }
        
        // Read file contents
        let data = try Data(contentsOf: fileURL)
        
        // Parse JSON Lines format
        let lines = String(data: data, encoding: .utf8)?
            .split(separator: "\n", omittingEmptySubsequences: true) ?? []
        
        var entries: [HistoryEntry<T>] = []
        let decoder = JSONDecoder()
        
        for (index, line) in lines.enumerated() {
            guard let lineData = line.data(using: .utf8) else {
                logger.warning("Failed to convert line \(index) to data, skipping")
                continue
            }
            
            do {
                let entry = try decoder.decode(HistoryEntry<T>.self, from: lineData)
                entries.append(entry)
            } catch {
                logger.warning("Failed to decode line \(index): \(error.localizedDescription), skipping")
            }
        }
        
        logger.info("Loaded \(entries.count) entries from disk")
        return entries
    }
    
    /// Command 2: Append one entry to end of file as JSON line
    func append<T: Codable>(_ entry: HistoryEntry<T>) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(entry)
        
        // Ensure directory exists
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        // Append to file with newline
        var lineData = data
        lineData.append(contentsOf: [0x0A]) // Newline character
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            // Append to existing file
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            try fileHandle.seekToEnd()
            try fileHandle.write(contentsOf: lineData)
            try fileHandle.close()
        } else {
            // Create new file
            try lineData.write(to: fileURL)
        }
        
        logger.debug("Appended entry to disk")
    }
    
    /// Command 3: Replace entire file with array of entries as JSON lines
    func rewrite<T: Codable>(_ entries: [HistoryEntry<T>]) throws {
        let encoder = JSONEncoder()
        
        // Encode all entries as JSON lines
        var fileData = Data()
        for entry in entries {
            let entryData = try encoder.encode(entry)
            fileData.append(entryData)
            fileData.append(contentsOf: [0x0A]) // Newline character
        }
        
        // Ensure directory exists
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        // Write to file (replaces existing content)
        try fileData.write(to: fileURL, options: .atomic)
        
        logger.info("Rewrote history file with \(entries.count) entries")
    }
}

// MARK: - Convenience Extensions

extension ChronologicalHistoryManager {
    
    /// Create a manager with a file in the Application Support directory
    /// - Parameter filename: Name of the file (e.g., "history.jsonl")
    /// - Returns: A configured history manager, or nil if the directory cannot be accessed
    static func inApplicationSupport(filename: String) -> ChronologicalHistoryManager<Entry>? {
        guard let appSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }
        
        let fileURL = appSupportURL.appendingPathComponent(filename)
        return ChronologicalHistoryManager(fileURL: fileURL)
    }
    
    /// Create a manager with a file in the Documents directory
    /// - Parameter filename: Name of the file (e.g., "history.jsonl")
    /// - Returns: A configured history manager, or nil if the directory cannot be accessed
    static func inDocuments(filename: String) -> ChronologicalHistoryManager<Entry>? {
        guard let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }
        
        let fileURL = documentsURL.appendingPathComponent(filename)
        return ChronologicalHistoryManager(fileURL: fileURL)
    }
}
