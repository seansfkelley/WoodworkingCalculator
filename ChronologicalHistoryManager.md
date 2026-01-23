# Design Document: ChronologicalHistoryManager

## Overview

The `ChronologicalHistoryManager` is a generic, file-backed history management subsystem designed to track calculations entered by the user. It provides efficient append and list operations while supporting infrequent deletions, optimized for the common case of appending new entries and reading recent history.

## Goals

1. **Generic Design**: Support any type conforming to `Codable` (the wrapper provides ID and timestamp)
2. **Performance**: Optimize for frequent appends and list operations
3. **Persistence**: Maintain state across app launches using a JSON-lines file format
4. **Simplicity**: Provide a clean, type-safe Swift API

## Architecture

### File Format

The history is stored in a **JSON Lines** format (`.jsonl` or newline-delimited JSON):
- Each line contains one complete JSON object
- Lines are separated by newline characters (`\n`)
- File is append-friendly (no need to parse/rewrite on add)
- Each entry includes a timestamp for chronological ordering

```
{"id":"...","timestamp":1737590400.0,"data":{...}}
{"id":"...","timestamp":1737590401.0,"data":{...}}
{"id":"...","timestamp":1737590402.0,"data":{...}}
```

### Data Model

```swift
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
```

### In-Memory Cache

The manager maintains an in-memory array of entries as the source of truth:
- Stored internally in chronological order (oldest to newest) for efficient appends
- Presented as reverse-chronological order (latest first) via a reversed view
- Loaded on initialization from the file (already in chronological order)
- Updated synchronously on append/delete operations
- All reads come from this cache, never from disk
- Reversal is lazy and only happens when accessed, which is rare since history view is infrequently opened

### Concurrency Model

- The public API is a simple `struct` with in-memory cache as the source of truth
- Implementation detail: an internal `actor` handles **only disk I/O** with no state
- The actor provides exactly **three commands**:
  1. **Read** - Load entire file into memory
  2. **Append** - Write one entry to end of file
  3. **Rewrite** - Replace entire file contents
- **Ordering guarantee**: Actor isolation automatically serializes all disk operations in FIFO order
- Operations on the public struct update memory immediately, then send fire-and-forget commands to the actor
- This keeps the API simple, highly responsive, and maintains a clear separation between memory and persistence

### Error Handling Strategy

Since history is not crucial to app functionality:
- Operations do **not throw** errors and are synchronous
- Memory updates happen immediately and never fail
- Disk I/O happens asynchronously in the background via the actor
- Disk I/O errors are logged but do not affect the in-memory state
- File inconsistencies are resolved on the next successful write (eventual consistency)
- Initialization never blocks - app starts immediately with empty state
- Background merge happens transparently when disk load completes
- This ensures the UI remains maximally responsive even if disk operations fail

## API Design

```swift
@Observable
final class ChronologicalHistoryManager<Entry: Codable> {
    
    // MARK: - Initialization
    
    /// Initialize with a file URL
    /// Returns immediately with empty state. Loads existing history from disk asynchronously.
    /// When disk load completes, merges with any new entries added in the meantime.
    /// - Parameter fileURL: Location of the JSON-lines history file
    init(fileURL: URL)
    
    // MARK: - Properties
    
    /// All entries in reverse-chronological order (latest first)
    /// Observable - SwiftUI views automatically update when this changes
    /// Note: Internally stored in chronological order, reversed lazily on access
    var entries: [HistoryEntry<Entry>] { get }
    
    // MARK: - Operations
    
    /// Append a new entry with the current timestamp
    /// Updates in-memory state immediately. Disk write happens asynchronously in the background.
    /// - Parameter entry: The entry to append
    func append(_ entry: Entry)
    
    /// Delete entries by their IDs
    /// Updates in-memory state immediately. Disk rewrite happens asynchronously in the background.
    /// - Parameter ids: Set of IDs to delete
    func delete(ids: Set<UUID>)
}
```

## Implementation Details

### Internal Actor Design

The manager uses a stateless internal actor for disk I/O with exactly three commands:

```swift
@Observable
final class ChronologicalHistoryManager<Entry: Codable> {
    // Internal storage in chronological order (oldest first)
    private var _entries: [HistoryEntry<Entry>] = []
    
    // Public computed property returns reversed view
    var entries: [HistoryEntry<Entry>] {
        _entries.reversed()
    }
    
    init(fileURL: URL) {
        // Start with empty cache, return immediately
        // Fire-and-forget: Task { await loadAndMerge() }
    }
    
    func append(_ entry: Entry) {
        // Create HistoryEntry wrapper, append to end of _entries (O(1) amortized)
        // Observation system automatically notifies SwiftUI
        // Fire-and-forget: Task { await diskIO.append(...) }
    }
    
    func delete(ids: Set<UUID>) {
        // Remove matching entries from _entries array
        // Observation system automatically notifies SwiftUI
        // Fire-and-forget: Task { await diskIO.rewrite(snapshot) }
    }
    
    private func loadAndMerge() {
        // Read from disk (entries already in chronological order)
        // Check if entries were added during load
        // If empty: just set _entries to loaded entries (no merge or reversal needed)
        // If not empty: concatenate loaded + current _entries, then rewrite to disk
        // Trigger observation (view will reverse when accessed)
    }
}

private actor DiskIOActor {
    // Command 1: Read entire file, return array of entries or nil
    func read() -> [HistoryEntry<Entry>]?
    
    // Command 2: Append one entry to end of file as JSON line
    func append<T: Codable>(_ entry: HistoryEntry<T>)
    
    // Command 3: Replace entire file with array of entries as JSON lines
    func rewrite<T: Codable>(_ entries: [HistoryEntry<T>])
}
```

This pattern ensures:
- **Stateless actor**: Only performs I/O operations, no data storage
- **Three simple commands**: Read, Append, Rewrite - nothing more
- **Observable class**: SwiftUI views automatically update when `_entries` changes
- **Automatic serialization**: Actor ensures disk writes happen in order
- **Non-blocking init**: App starts immediately, history loads in background
- **SwiftUI integration**: No manual `objectWillChange.send()` needed with `@Observable`
- **Efficient appends**: O(1) amortized by appending to array instead of prepending
- **Lazy reversal**: Reversed view is only computed when accessed, typically rare

### Initialization

1. Initialize the `_entries` array as empty (stored in chronological order)
2. Create the stateless `DiskIOActor` with the `fileURL`
3. Return immediately (non-blocking)
4. Spawn a background task to load and merge:
   - Call the **read command** asynchronously to load existing history from disk
   - If entries are found (already in chronological order):
     - Check if any entries were added to memory while waiting for disk read
     - **If no entries were added**: Simply set `_entries` to loaded entries (no merge or reversal needed)
     - **If entries were added during load**: Merge is required:
       - Concatenate: loaded entries (older) + current `_entries` (newer)
       - Call **rewrite command** to persist the merged state back to disk
     - Trigger observation (SwiftUI views will see reversed view on access)
   - If read fails, log the error and continue (memory state remains valid)

### Append Operation

**Optimized for performance (efficient array append):**

1. Create a new `HistoryEntry<Entry>` with the current timestamp
2. Append to the end of the `_entries` array (O(1) amortized, maintained in chronological order)
3. Observation system automatically notifies any SwiftUI views observing this property
4. Return immediately (synchronous)
5. Spawn a fire-and-forget task that calls the **append command**
6. Actor receives the entry and writes JSON-encoded bytes to the end of the file with a trailing newline
7. If file write fails, log the error (memory state is already updated and authoritative)
8. Complexity: O(1) for memory update (amortized), O(1) for spawning task, O(1) for disk append (serialized)
9. Note: Views access `entries` computed property which returns reversed view, showing newest first

### List Operation

**Optimized for performance:**

1. Access the `entries` computed property which returns `_entries.reversed()`
2. Swift's `.reversed()` returns a lazy `ReversedCollection` view (O(1) to create, no actual copying)
3. Completely synchronous, no I/O involved
4. SwiftUI views that read this property are automatically tracked by the observation system
5. When `_entries` changes, SwiftUI views update automatically
6. Complexity: O(1) to create reversed view, O(n) when actually iterating (done by the view)
7. Since history view is rarely opened, the reversal overhead is minimal

### Delete Operation

**Rewrite strategy (acceptable for rare operations):**

1. Remove entries with matching IDs from the `_entries` array
2. Observation system automatically notifies any SwiftUI views observing this property
3. Create a snapshot of the updated array (still in chronological order)
4. Return immediately (synchronous)
5. Spawn a fire-and-forget task that calls the **rewrite command**
6. Actor receives the snapshot and replaces the entire file contents:
   - Encode all entries to JSON lines (already in chronological order, matching file format)
   - Write to file, replacing previous contents
   - If write fails, log the error (memory state is already updated and authoritative)
7. Complexity: O(n) for filtering, O(1) for spawning task, O(n) for disk rewrite (serialized)

### Error Handling

- File I/O errors are logged using `OSLog` with appropriate log levels
- All public API operations are synchronous and update memory immediately
- Disk operations happen in background via stateless actor
- Actor serializes disk operations automatically (FIFO order)
- In-memory cache is the authoritative source of truth
- Disk is a best-effort persistence layer
- If disk writes fail, memory remains correct; data will be persisted on next successful operation
- On initialization, loading happens in the background; app starts immediately with empty state
- Background merge reconciles disk and memory states transparently

### File Location

Recommend storing in the app's Documents directory (for user data that might be backed up):

```swift
let fileURL = FileManager.default
    .urls(for: .documentDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("history.jsonl")
```

Or Application Support for app-generated data that doesn't need to be user-visible:

```swift
let fileURL = FileManager.default
    .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("history.jsonl")
```

**Recommendation**: Use **Application Support** for calculation history since:
- It's app-generated data, not user-created documents
- It's automatically backed up by iCloud/iTunes
- It's hidden from the Files app (appropriate for internal data)
- It persists across app updates

## Usage Example

## Testing Strategy

1. **Unit Tests**:
   - Append single and multiple entries
   - Verify reverse-chronological ordering
   - Test deletion of one, multiple, and all entries
   - Test persistence across manager instances
   - Test with empty file
   - Test graceful handling of file I/O errors (verify in-memory state is correct)
   - Test recovery after failed writes
   - Test background load and merge behavior:
     - **Testing merge scenarios**: To test the case where entries are added before disk load completes:
       - Option 1: Use a custom test `DiskIOActor` that adds artificial delays to the `read()` command
       - Option 2: Use a coordination mechanism (like `XCTestExpectation` or semaphores) to block the disk read until after appends are made
       - Option 3: Use dependency injection to provide a mock actor with controllable timing
     - Verify that entries added during load appear first (newest)
     - Verify that loaded entries appear after in-memory entries (older)
     - Verify rewrite only happens when merge is needed (entries.isEmpty == false when load completes)
     - Verify no rewrite when no entries added during load (entries.isEmpty == true when load completes)
