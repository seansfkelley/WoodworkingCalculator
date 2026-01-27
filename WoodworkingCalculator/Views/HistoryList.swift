import SwiftUI

protocol Timestamped {
    var timestamp: Date { get }
}

func groupByTimeIntervals<T: Timestamped>(items: [T]) -> [(TelescopingTimeBound, [T])] {
    let calendar = Calendar.current
    let lastMidnight = calendar.startOfDay(for: Date())
    
    let boundaries: [(Date, TelescopingTimeBound)] = [
        (lastMidnight, .today),
        (calendar.date(byAdding: .day, value: -1, to: lastMidnight)!, .yesterday),
        (calendar.date(byAdding: .day, value: -7, to: lastMidnight)!, .pastWeek),
        (calendar.date(byAdding: .month, value: -1, to: lastMidnight)!, .pastMonth),
        (Date.distantPast, .older),
    ]
    
    var result: [(TelescopingTimeBound, [T])] = []
    var currentEntries: [T] = []
    var remainingBoundaries = boundaries
    
    for item in items {
        while !remainingBoundaries.isEmpty && item.timestamp < remainingBoundaries.first!.0 {
            if !currentEntries.isEmpty {
                result.append((remainingBoundaries.first!.1, currentEntries))
                currentEntries = []
            }
            remainingBoundaries.removeFirst()
        }
        
        currentEntries.append(item)
    }
    
    if !currentEntries.isEmpty {
        let interval = remainingBoundaries.isEmpty ? boundaries.last!.1 : remainingBoundaries[0].1
        result.append((interval, currentEntries))
    }
    
    return result
}

enum TelescopingTimeBound: Equatable {
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

    var body: some View {
        NavigationStack {
            Group {
                if historyManager.entries.isEmpty {
                    ContentUnavailableView(
                        "No History",
                        systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                        description: Text("Calculations you perform will appear here.")
                    )
                } else {
                    List(selection: $selectedIDs) {
                        ForEach(groupByTimeIntervals(items: historyManager.entries.reversed()), id: \.0) { interval, entries in
                            Section(interval.displayName) {
                                ForEach(entries) { entry in
                                    Button {
                                        if editMode == .inactive {
                                            onSelectEntry(entry.data.input, entry.data.result.quantity)
                                            dismiss()
                                        }
                                    } label: {
                                        HistoryListItem(
                                            entry: entry.data,
                                            formattingOptions: formattingOptions
                                        )
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
                                            UIPasteboard.general.string = entry.data.formattedResult.withPrettyNumbers
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

private struct HistoryListItem: View {
    let entry: StoredCalculation
    let formattingOptions: Quantity.FormattingOptions
    @State private var showingPopover = false
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.input.withPrettyNumbers)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(entry.formattedResult.withPrettyNumbers)
                    .font(.body)
                    .foregroundStyle(.primary)
            }

            let upToDateFormattedResult = entry.result.quantity.formatted(with: formattingOptions).0
            if entry.formattedResult != upToDateFormattedResult {
                Spacer()
                Button {
                    showingPopover = true
                } label: {
                    Image(systemName: "notequal")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                .buttonStyle(.plain)
                .popover(
                    isPresented: $showingPopover,
                    attachmentAnchor: .point(.bottom),
                    arrowEdge: .top
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Settings changed since this was calculated.")
                            .font(.body)
                        HStack(spacing: 4) {
                            VStack(spacing: 2) {
                                Text(entry.formattedResult.withPrettyNumbers)
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
                                Text(upToDateFormattedResult.withPrettyNumbers)
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
    }
}
