import Testing
import Foundation
@testable import Wood_Calc

@Suite
struct ChronologicalHistoryManagerTests : ~Copyable {
    let manager: ChronologicalHistoryManager<String>
    let fileURL: URL
    
    init() {
        fileURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("test_history_\(UUID().uuidString).jsonl")
        manager = ChronologicalHistoryManager<String>(fileURL: fileURL)
    }
    
    deinit {
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    func loadEntriesFromFile() throws -> [HistoryEntry<String>] {
        let contents = try String(contentsOf: fileURL, encoding: .utf8)
        let decoder = JSONDecoder()
        return contents.split(separator: "\n").compactMap { line in
            try? decoder.decode(HistoryEntry<String>.self, from: Data(line.utf8))
        }
    }
    
    @Test
    func initializeEmpty() async throws {
        #expect(manager.entries.isEmpty)
    }
    
    @Test
    func appendSingle() async throws {
        let calculation = "2 + 2 = 4"
        manager.append(calculation)
        
        #expect(manager.entries.map(\.data) == [calculation])
        try await Task.sleep(for: .milliseconds(100))
        
        let persisted = try loadEntriesFromFile()
        #expect(persisted.count == 1)
        #expect(persisted.map(\.data) == [calculation])
    }
    
    @Test
    func appendMultipleInOrder() async throws {
        for i in 1...5 {
            manager.append("calculation \(i)")
            try await Task.sleep(for: .milliseconds(10))
        }
        
        #expect(manager.entries.map(\.data) == [
            "calculation 1",
            "calculation 2",
            "calculation 3",
            "calculation 4",
            "calculation 5"
        ])
        
        for i in 0..<(manager.entries.count - 1) {
            #expect(manager.entries[i].timestamp < manager.entries[i + 1].timestamp)
        }
    }
    
    @Test
    func deleteSingle() async throws {
        manager.append("1 + 1 = 2")
        manager.append("2 + 2 = 4")
        manager.append("3 + 3 = 6")
        
        #expect(manager.entries.count == 3)
        
        let idToDelete = manager.entries[1].id
        manager.delete(ids: [idToDelete])
        
        #expect(manager.entries.count == 2)
        #expect(!manager.entries.contains(where: { $0.id == idToDelete }))
        
        try await Task.sleep(for: .milliseconds(100))
        
        let persisted = try loadEntriesFromFile()
        #expect(persisted.count == 2)
        #expect(!persisted.contains(where: { $0.id == idToDelete }))
    }
    
    @Test
    func deleteAll() async throws {
        for i in 1...3 {
            manager.append("calculation \(i)")
        }
        
        let allIds = Set(manager.entries.map { $0.id })
        manager.delete(ids: allIds)
        
        #expect(manager.entries.isEmpty)
        
        try await Task.sleep(for: .milliseconds(100))
        
        let persisted = try loadEntriesFromFile()
        #expect(persisted.isEmpty)
    }
    
    @Test
    func deleteNonExistent() async throws {
        manager.append("1 + 1 = 2")
        
        #expect(manager.entries.count == 1)
        
        manager.delete(ids: [UUID()])
        
        #expect(manager.entries.count == 1)
    }
    
    @Test
    func persistenceAcrossInstances() async throws {
        do {
            let manager = ChronologicalHistoryManager<String>(fileURL: fileURL)
            manager.append("calculation 1")
            manager.append("calculation 2")
            
            try await Task.sleep(for: .milliseconds(100))
        }
        
        do {
            let manager = ChronologicalHistoryManager<String>(fileURL: fileURL)
            try await Task.sleep(for: .milliseconds(100))
            
            #expect(manager.entries.map(\.data) == ["calculation 1", "calculation 2"])
        }
        
        do {
            let manager = ChronologicalHistoryManager<String>(fileURL: fileURL)
            try await Task.sleep(for: .milliseconds(100))
            
            #expect(manager.entries.count == 2)
            
            manager.append("calculation 3")
            try await Task.sleep(for: .milliseconds(100))
            
            #expect(manager.entries.count == 3)
        }
        
        do {
            let manager = ChronologicalHistoryManager<String>(fileURL: fileURL)
            try await Task.sleep(for: .milliseconds(100))
            
            #expect(manager.entries.map(\.data) == ["calculation 1", "calculation 2", "calculation 3"])
        }
    }
    
    @Test
    func loadFromExistingFile() async throws {
        let entries = [
            HistoryEntry(data: "calculation 1"),
            HistoryEntry(data: "calculation 2")
        ]
        
        let encoder = JSONEncoder()
        var fileData = Data()
        for entry in entries {
            let entryData = try encoder.encode(entry)
            fileData.append(entryData)
            fileData.append(contentsOf: [0x0A]) // Newline
        }
        
        try fileData.write(to: fileURL)
        
        let manager = ChronologicalHistoryManager<String>(fileURL: fileURL)
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(manager.entries.map(\.data) == ["calculation 1", "calculation 2"])
    }
    
    @Test
    func emptyFile() async throws {
        try Data().write(to: fileURL)
        
        let manager = ChronologicalHistoryManager<String>(fileURL: fileURL)
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(manager.entries.isEmpty)
        
        manager.append("first entry")
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(manager.entries.count == 1)
        #expect(manager.entries.map(\.data) == ["first entry"])
    }
    
    @Test
    func corruptedLine() async throws {
        let validEntry = HistoryEntry(data: "valid calculation")
        let encoder = JSONEncoder()
        
        var fileData = Data()
        fileData.append(try encoder.encode(validEntry))
        fileData.append(contentsOf: [0x0A])
        fileData.append("{ corrupted json }".data(using: .utf8)!)
        fileData.append(contentsOf: [0x0A])
        
        try fileData.write(to: fileURL)
        
        let manager = ChronologicalHistoryManager<String>(fileURL: fileURL)
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(manager.entries.map(\.data) == ["valid calculation"])
    }
    
    @Test
    func mergeEntriesDuringLoad() async throws {
        let diskEntry = HistoryEntry(data: "disk entry")
        let encoder = JSONEncoder()
        var fileData = Data()
        fileData.append(try encoder.encode(diskEntry))
        fileData.append(contentsOf: [0x0A])
        try fileData.write(to: fileURL)
        
        let manager = ChronologicalHistoryManager<String>(fileURL: fileURL)
        manager.append("memory entry")
        // This is probably flaky, but whatever.
        #expect(manager.entries.map(\.data) == ["memory entry"])

        try await Task.sleep(for: .milliseconds(200))
        
        #expect(manager.entries.map(\.data) == ["disk entry", "memory entry"])
        
        let persisted = try loadEntriesFromFile()
        #expect(persisted.count == 2)
        #expect(persisted.map(\.data) == ["disk entry", "memory entry"])
    }

    @Test
    func oldEntriesAreDeletedDuringLoad() async throws {
        let calendar = Calendar.current
        let now = Date()

        let recentEntry = HistoryEntry(
            data: "Recent calculation",
            timestamp: try #require(calendar.date(byAdding: .day, value: -30, to: now))
        )
        let oldEntry = HistoryEntry(
            data: "Old calculation",
            timestamp: try #require(calendar.date(byAdding: .year, value: -2, to: now))
        )
        let veryOldEntry = HistoryEntry(
            data: "Very old calculation",
            timestamp: try #require(calendar.date(byAdding: .year, value: -5, to: now))
        )

        let encoder = JSONEncoder()
        var fileData = Data()
        for entry in [recentEntry, oldEntry, veryOldEntry] {
            let entryData = try encoder.encode(entry)
            fileData.append(entryData)
            fileData.append(contentsOf: "\n".utf8)
        }
        try fileData.write(to: fileURL)

        let manager = ChronologicalHistoryManager<String>(fileURL: fileURL)

        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.entries.count == 1)
        #expect(manager.entries[0].data == "Recent calculation")
    }
}
