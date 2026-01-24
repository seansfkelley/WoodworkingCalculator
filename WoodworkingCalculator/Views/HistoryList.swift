import SwiftUI

// To preserve migration safety, this should not store anything beyond primitives or types defined here.
struct StoredCalculation: Codable {
    enum Result: Codable {
        case real(Double, UInt)
        case rational(Int, Int, UInt)

        static func from(quantity: Quantity) -> Result {
            switch quantity {
            case .real(let value, let dimension): .real(value, dimension.value)
            case .rational(let rational, let dimension): .rational(rational.num, rational.den, dimension.value)
            }
        }

        var quantity: Quantity {
            switch self {
            case .real(let value, let dimension): .real(value, .init(dimension))
            case .rational(let num, let den, let dimension): .rational(UncheckedRational(num, den).unsafe, .init(dimension))
            }
        }
    }

    let input: String
    let result: Result
    let formattedResult: String
}

private enum TimeInterval: CaseIterable {
    case today
    case yesterday
    case pastWeek
    case pastMonth
    case older

    var displayName: String {
        switch self {
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .pastWeek: return "Past Week"
        case .pastMonth: return "Past Month"
        case .older: return "Older"
        }
    }
}

struct HistoryList: View {
    let historyManager: ChronologicalHistoryManager<StoredCalculation>
    let formattingOptions: Quantity.FormattingOptions
    let onSelectEntry: (String, Quantity) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var editMode: EditMode = .inactive
    @State private var selectedIDs: Set<UUID> = []
    @State private var popoverEntryID: UUID?

    private var groupedSearchHistory: [(TimeInterval, [HistoryEntry<StoredCalculation>])] {
        let calendar = Calendar.current
        let lastMidnight = calendar.startOfDay(for: Date())

        var boundaries: [(Date, TimeInterval)] = [
            (lastMidnight, .today),
            (calendar.date(byAdding: .day, value: -1, to: lastMidnight)!, .yesterday),
            (calendar.date(byAdding: .day, value: -7, to: lastMidnight)!, .pastWeek),
            (calendar.date(byAdding: .month, value: -1, to: lastMidnight)!, .pastMonth),
            (Date.distantPast, .older),
        ]

        var result: [(TimeInterval, [HistoryEntry<StoredCalculation>])] = []
        var currentEntries: [HistoryEntry<StoredCalculation>] = []

        for entry in historyManager.entries.reversed() {
            while !boundaries.isEmpty && entry.timestamp < boundaries.first!.0 {
                if !currentEntries.isEmpty {
                    result.append((boundaries.first!.1, currentEntries))
                    currentEntries = []
                }
                boundaries.removeFirst()
            }

            currentEntries.append(entry)
        }

        if !currentEntries.isEmpty {
            let interval = boundaries.isEmpty ? .older : boundaries[0].1
            result.append((interval, currentEntries))
        }

        return result
    }

    var body: some View {
        NavigationStack {
            Group {
                if historyManager.entries.isEmpty {
                    ContentUnavailableView(
                        "No History",
                        systemImage: "clock",
                        description: Text("Calculations you perform will appear here.")
                    )
                } else {
                    List(selection: $selectedIDs) {
                        ForEach(groupedSearchHistory, id: \.0) { interval, entries in
                            Section(interval.displayName) {
                                ForEach(entries) { entry in
                                    Button {
                                        if editMode == .inactive {
                                            onSelectEntry(entry.data.input, entry.data.result.quantity)
                                            dismiss()
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(prettyPrintExpression(entry.data.input))
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)

                                                Text(prettyPrintExpression(entry.data.formattedResult))
                                                    .font(.body)
                                                    .foregroundStyle(.primary)
                                            }
                                            .padding(.vertical, 4)

                                            let upToDateFormattedResult = entry.data.result.quantity.formatted(with: formattingOptions).0
                                            if entry.data.formattedResult != upToDateFormattedResult {
                                                Spacer()
                                                Button {
                                                    popoverEntryID = entry.id
                                                } label: {
                                                    Image(systemName: "notequal")
                                                        .font(.title2)
                                                        .foregroundStyle(.secondary)
                                                        .padding()
                                                }
                                                .buttonStyle(.plain)
                                                .popover(
                                                    isPresented: Binding(
                                                        get: { popoverEntryID == entry.id },
                                                        set: { if !$0 { popoverEntryID = nil } }
                                                    ),
                                                    attachmentAnchor: .point(.bottom),
                                                    arrowEdge: .top
                                                ) {
                                                    VStack(alignment: .leading, spacing: 6) {
                                                        Text("Settings changed since this was calculated.")
                                                            .font(.body)
                                                        HStack(spacing: 4) {
                                                            VStack(spacing: 2) {
                                                                Text(prettyPrintExpression(entry.data.formattedResult))
                                                                    .font(.title2)
                                                                Text("previous")
                                                                    .font(.caption)
                                                                    .foregroundStyle(.secondary)
                                                            }
                                                            .padding(.horizontal, 8)
                                                            .padding(.vertical, 4)
                                                            .background(.secondary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                                                            Image(systemName: "arrow.right")
                                                            VStack(spacing: 2) {
                                                                Text(prettyPrintExpression(upToDateFormattedResult))
                                                                    .font(.title2)
                                                                Text("current")
                                                                    .font(.caption)
                                                                    .foregroundStyle(.secondary)
                                                            }
                                                            .padding(.horizontal, 8)
                                                            .padding(.vertical, 4)
                                                            .background(.secondary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                                                        }
                                                    }
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .padding()
                                                    .presentationCompactAdaptation(.popover)
                                                }
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            historyManager.delete(ids: [entry.id])
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }

                                        Button {
                                            UIPasteboard.general.string = entry.data.formattedResult
                                        } label: {
                                            Label("Copy", systemImage: "doc.on.doc")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .environment(\.editMode, $editMode)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if editMode == .active {
                        Button {
                            withAnimation {
                                editMode = .inactive
                                selectedIDs.removeAll()
                            }
                        } label: {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.orange)
                        }
                    } else {
                        Button("Edit") {
                            withAnimation {
                                editMode = .active
                            }
                        }
                        .disabled(historyManager.entries.isEmpty)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if editMode == .active {
                        Button {
                            let idsToDelete = selectedIDs.isEmpty ? Set(historyManager.entries.map(\.id)) : selectedIDs
                            historyManager.delete(ids: idsToDelete)
                            selectedIDs.removeAll()
                        } label: {
                            if selectedIDs.isEmpty {
                                Text("Clear all")
                            } else {
                                Text("Delete (\(selectedIDs.count))")
                            }
                        }
                        .foregroundStyle(.red)
                    } else {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
            }
        }
    }
}
