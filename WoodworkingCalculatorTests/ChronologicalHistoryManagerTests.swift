//
//  ChronologicalHistoryManagerTests.swift
//
//  Comprehensive test suite for ChronologicalHistoryManager
//
//  Created on January 23, 2026.
//

import Testing
import Foundation
@testable import ChronologicalHistoryManager

// MARK: - Test Models

/// Simple test data type
struct CalculationData: Codable, Equatable {
    let expression: String
    let result: Double
}

// MARK: - Test Utilities

extension ChronologicalHistoryManagerTests {
    
    /// Create a temporary file URL for testing
    func createTempFileURL() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "test_history_\(UUID().uuidString).jsonl"
        return tempDir.appendingPathComponent(filename)
    }
    
    /// Clean up a test file
    func cleanupFile(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Tests

@Suite("ChronologicalHistoryManager Tests")
struct ChronologicalHistoryManagerTests {
    
    // MARK: - Basic Functionality Tests
    
    @Test("Initialize with empty history")
    func initializeEmpty() async throws {
        let fileURL = createTempFileURL()
        defer { cleanupFile(fileURL) }
        
        let manager = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
        
        // Should start empty immediately
        #expect(manager.entries.isEmpty)
    }
    
    @Test("Append single entry")
    func appendSingle() async throws {
        let fileURL = createTempFileURL()
        defer { cleanupFile(fileURL) }
        
        let manager = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
        
        let calculation = CalculationData(expression: "2 + 2", result: 4.0)
        manager.append(calculation)
        
        // Should be immediately available in memory
        #expect(manager.entries.count == 1)
        #expect(manager.entries[0].data == calculation)
        
        // Wait for background disk write to complete
        try await Task.sleep(for: .milliseconds(100))
        
        // Verify persistence by creating new manager
        let manager2 = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(manager2.entries.count == 1)
        #expect(manager2.entries[0].data == calculation)
    }
    
    @Test("Append multiple entries")
    func appendMultiple() async throws {
        let fileURL = createTempFileURL()
        defer { cleanupFile(fileURL) }
        
        let manager = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
        
        let calculations = [
            CalculationData(expression: "2 + 2", result: 4.0),
            CalculationData(expression: "5 * 3", result: 15.0),
            CalculationData(expression: "10 / 2", result: 5.0)
        ]
        
        for calc in calculations {
            manager.append(calc)
        }
        
        // All should be immediately available
        #expect(manager.entries.count == 3)
        
        // Verify reverse-chronological order (latest first)
        #expect(manager.entries[0].data == calculations[2])
        #expect(manager.entries[1].data == calculations[1])
        #expect(manager.entries[2].data == calculations[0])
        
        // Wait for background writes
        try await Task.sleep(for: .milliseconds(100))
        
        // Verify persistence
        let manager2 = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(manager2.entries.count == 3)
        #expect(manager2.entries[0].data == calculations[2])
    }
    
    // MARK: - Ordering Tests
    
    @Test("Entries are in reverse-chronological order")
    func reverseChronologicalOrder() async throws {
        let fileURL = createTempFileURL()
        defer { cleanupFile(fileURL) }
        
        let manager = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
        
        // Add entries with slight delays to ensure different timestamps
        for i in 1...5 {
            manager.append(CalculationData(expression: "\(i)", result: Double(i)))
            try await Task.sleep(for: .milliseconds(10))
        }
        
        // Verify newest entries come first
        #expect(manager.entries.count == 5)
        #expect(manager.entries[0].data.result == 5.0)
        #expect(manager.entries[1].data.result == 4.0)
        #expect(manager.entries[2].data.result == 3.0)
        #expect(manager.entries[3].data.result == 2.0)
        #expect(manager.entries[4].data.result == 1.0)
        
        // Verify timestamps are in reverse order
        for i in 0..<(manager.entries.count - 1) {
            #expect(manager.entries[i].timestamp > manager.entries[i + 1].timestamp)
        }
    }
    
    // MARK: - Deletion Tests
    
    @Test("Delete single entry")
    func deleteSingle() async throws {
        let fileURL = createTempFileURL()
        defer { cleanupFile(fileURL) }
        
        let manager = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
        
        manager.append(CalculationData(expression: "1 + 1", result: 2.0))
        manager.append(CalculationData(expression: "2 + 2", result: 4.0))
        manager.append(CalculationData(expression: "3 + 3", result: 6.0))
        
        #expect(manager.entries.count == 3)
        
        let idToDelete = manager.entries[1].id
        manager.delete(ids: [idToDelete])
        
        // Should be immediately removed from memory
        #expect(manager.entries.count == 2)
        #expect(!manager.entries.contains(where: { $0.id == idToDelete }))
        
        // Wait for background rewrite
        try await Task.sleep(for: .milliseconds(100))
        
        // Verify persistence
        let manager2 = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(manager2.entries.count == 2)
        #expect(!manager2.entries.contains(where: { $0.id == idToDelete }))
    }
    
    @Test("Delete multiple entries")
    func deleteMultiple() async throws {
        let fileURL = createTempFileURL()
        defer { cleanupFile(fileURL) }
        
        let manager = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
        
        for i in 1...5 {
            manager.append(CalculationData(expression: "\(i)", result: Double(i)))
        }
        
        #expect(manager.entries.count == 5)
        
        let idsToDelete = Set([manager.entries[1].id, manager.entries[3].id])
        manager.delete(ids: idsToDelete)
        
        #expect(manager.entries.count == 3)
        
        // Wait for background rewrite
        try await Task.sleep(for: .milliseconds(100))
        
        // Verify persistence
        let manager2 = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(manager2.entries.count == 3)
    }
    
    @Test("Delete all entries")
    func deleteAll() async throws {
        let fileURL = createTempFileURL()
        defer { cleanupFile(fileURL) }
        
        let manager = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
        
        for i in 1...3 {
            manager.append(CalculationData(expression: "\(i)", result: Double(i)))
        }
        
        let allIds = Set(manager.entries.map { $0.id })
        manager.delete(ids: allIds)
        
        #expect(manager.entries.isEmpty)
        
        // Wait for background rewrite
        try await Task.sleep(for: .milliseconds(100))
        
        // Verify persistence
        let manager2 = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(manager2.entries.isEmpty)
    }
    
    @Test("Delete non-existent entry")
    func deleteNonExistent() async throws {
        let fileURL = createTempFileURL()
        defer { cleanupFile(fileURL) }
        
        let manager = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
        
        manager.append(CalculationData(expression: "1 + 1", result: 2.0))
        
        #expect(manager.entries.count == 1)
        
        // Try to delete an ID that doesn't exist
        manager.delete(ids: [UUID()])
        
        // Should still have the original entry
        #expect(manager.entries.count == 1)
    }
    
    // MARK: - Persistence Tests
    
    @Test("Persistence across manager instances")
    func persistenceAcrossInstances() async throws {
        let fileURL = createTempFileURL()
        defer { cleanupFile(fileURL) }
        
        // First manager: add entries
        do {
            let manager = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
            manager.append(CalculationData(expression: "1 + 1", result: 2.0))
            manager.append(CalculationData(expression: "2 + 2", result: 4.0))
            
            // Wait for writes to complete
            try await Task.sleep(for: .milliseconds(100))
        }
        
        // Second manager: verify data persisted
        do {
            let manager = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
            try await Task.sleep(for: .milliseconds(100))
            
            #expect(manager.entries.count == 2)
            #expect(manager.entries[0].data.result == 4.0)
            #expect(manager.entries[1].data.result == 2.0)
        }
        
        // Third manager: add more entries
        do {
            let manager = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
            try await Task.sleep(for: .milliseconds(100))
            
            #expect(manager.entries.count == 2)
            
            manager.append(CalculationData(expression: "3 + 3", result: 6.0))
            try await Task.sleep(for: .milliseconds(100))
            
            #expect(manager.entries.count == 3)
        }
        
        // Fourth manager: verify all data
        do {
            let manager = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
            try await Task.sleep(for: .milliseconds(100))
            
            #expect(manager.entries.count == 3)
            #expect(manager.entries[0].data.result == 6.0)
            #expect(manager.entries[1].data.result == 4.0)
            #expect(manager.entries[2].data.result == 2.0)
        }
    }
    
    @Test("Load from existing file")
    func loadFromExistingFile() async throws {
        let fileURL = createTempFileURL()
        defer { cleanupFile(fileURL) }
        
        // Manually create a JSON Lines file
        let entries = [
            HistoryEntry(data: CalculationData(expression: "1 + 1", result: 2.0)),
            HistoryEntry(data: CalculationData(expression: "2 + 2", result: 4.0))
        ]
        
        let encoder = JSONEncoder()
        var fileData = Data()
        for entry in entries {
            let entryData = try encoder.encode(entry)
            fileData.append(entryData)
            fileData.append(contentsOf: [0x0A]) // Newline
        }
        
        try fileData.write(to: fileURL)
        
        // Load with manager
        let manager = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(manager.entries.count == 2)
        #expect(manager.entries[0].data.result == 4.0)
        #expect(manager.entries[1].data.result == 2.0)
    }
    
    // MARK: - Edge Cases
    
    @Test("Empty file handling")
    func emptyFile() async throws {
        let fileURL = createTempFileURL()
        defer { cleanupFile(fileURL) }
        
        // Create empty file
        try Data().write(to: fileURL)
        
        let manager = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(manager.entries.isEmpty)
    }
    
    @Test("Corrupted line handling")
    func corruptedLine() async throws {
        let fileURL = createTempFileURL()
        defer { cleanupFile(fileURL) }
        
        // Create file with one valid entry and one corrupted entry
        let validEntry = HistoryEntry(data: CalculationData(expression: "1 + 1", result: 2.0))
        let encoder = JSONEncoder()
        
        var fileData = Data()
        fileData.append(try encoder.encode(validEntry))
        fileData.append(contentsOf: [0x0A])
        fileData.append("{ corrupted json }".data(using: .utf8)!)
        fileData.append(contentsOf: [0x0A])
        
        try fileData.write(to: fileURL)
        
        // Manager should load the valid entry and skip the corrupted one
        let manager = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(manager.entries.count == 1)
        #expect(manager.entries[0].data.result == 2.0)
    }
    
    // MARK: - Background Merge Tests
    
    @Test("Merge entries added during load")
    func mergeEntriesDuringLoad() async throws {
        let fileURL = createTempFileURL()
        defer { cleanupFile(fileURL) }
        
        // Pre-populate file with entries
        let diskEntry = HistoryEntry(data: CalculationData(expression: "disk", result: 1.0))
        let encoder = JSONEncoder()
        var fileData = Data()
        fileData.append(try encoder.encode(diskEntry))
        fileData.append(contentsOf: [0x0A])
        try fileData.write(to: fileURL)
        
        // Create manager and immediately append (before load completes)
        let manager = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
        manager.append(CalculationData(expression: "memory", result: 2.0))
        
        // Wait for merge to complete
        try await Task.sleep(for: .milliseconds(200))
        
        // Should have both entries, with memory entry first (newest)
        #expect(manager.entries.count == 2)
        #expect(manager.entries[0].data.expression == "memory")
        #expect(manager.entries[1].data.expression == "disk")
        
        // Verify merge was persisted
        let manager2 = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(manager2.entries.count == 2)
        #expect(manager2.entries[0].data.expression == "memory")
        #expect(manager2.entries[1].data.expression == "disk")
    }
    
    @Test("No merge when no entries added during load")
    func noMergeWhenEmpty() async throws {
        let fileURL = createTempFileURL()
        defer { cleanupFile(fileURL) }
        
        // Pre-populate file with entries
        let diskEntry = HistoryEntry(data: CalculationData(expression: "disk", result: 1.0))
        let encoder = JSONEncoder()
        var fileData = Data()
        fileData.append(try encoder.encode(diskEntry))
        fileData.append(contentsOf: [0x0A])
        try fileData.write(to: fileURL)
        
        // Create manager without immediately appending
        let manager = ChronologicalHistoryManager<CalculationData>(fileURL: fileURL)
        
        // Wait for load to complete
        try await Task.sleep(for: .milliseconds(100))
        
        // Should have disk entry
        #expect(manager.entries.count == 1)
        #expect(manager.entries[0].data.expression == "disk")
        
        // Verify no unnecessary rewrite happened (file should be unchanged)
        let fileContents = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = fileContents.split(separator: "\n")
        #expect(lines.count == 1) // Only one line, no duplicate from merge
    }
    
    // MARK: - Convenience Initializers Tests
    
    @Test("Create in Application Support")
    func createInApplicationSupport() async throws {
        let manager = ChronologicalHistoryManager<CalculationData>
            .inApplicationSupport(filename: "test_history.jsonl")
        
        #expect(manager != nil)
        
        if let manager = manager {
            manager.append(CalculationData(expression: "test", result: 1.0))
            #expect(manager.entries.count == 1)
        }
    }
    
    @Test("Create in Documents")
    func createInDocuments() async throws {
        let manager = ChronologicalHistoryManager<CalculationData>
            .inDocuments(filename: "test_history.jsonl")
        
        #expect(manager != nil)
        
        if let manager = manager {
            manager.append(CalculationData(expression: "test", result: 1.0))
            #expect(manager.entries.count == 1)
        }
    }
}
