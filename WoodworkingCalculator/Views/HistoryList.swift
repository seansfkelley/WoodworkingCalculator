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
    let assumeInches: Bool
    let formattingOptions: Quantity.FormattingOptions
    let onSelectEntry: (String, EvaluationResult) -> Void
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
                                            onSelectEntry(entry.data.input, entry.data.result.deserialized)
                                            dismiss()
                                        }
                                    } label: {
                                        HistoryListItem(
                                            entry: entry.data,
                                            assumeInches: assumeInches,
                                            formattingOptions: formattingOptions
                                        )
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .listRowBackground(Color.clear)
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
                                .listRowSeparator(.visible, edges: .all)
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
    let assumeInches: Bool
    let formattingOptions: Quantity.FormattingOptions
    @State private var showingPopover = false
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.input.withPrettyNumbers)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text(entry.formattedResult.withPrettyNumbers)
                    .font(.title3)
                    .foregroundStyle(.primary)
            }

            let upToDateFormattedResult = entry
                .result
                .deserialized
                .quantity(assumingLengthIf: assumeInches)
                .formatted(with: formattingOptions)
                .0
            if entry.formattedResult != upToDateFormattedResult {
                Spacer()
                Button {
                    showingPopover = true
                } label: {
                    Image(systemName: "notequal")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .padding(4)
                }
                .buttonBorderShape(.circle)
                .buttonStyle(.bordered)
                .tint(.secondary)
                .popover(isPresented: $showingPopover) {
                    VStack(alignment: .center, spacing: 8) {
                        Text("Settings changed since this was calculated.")
                            .font(.body)
                            .frame(maxWidth: 200)
                            .multilineTextAlignment(.center)
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
                    .padding(20)
                    .presentationCompactAdaptation(.popover)
                }
            }
        }
    }
}

#Preview("With entries") {
    let manager = ChronologicalHistoryManager<StoredCalculation>(
        fileURL: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    )
    let options = Quantity.FormattingOptions(.inches, RationalPrecision(denominator: 16), Constants.DecimalPrecision.standard, Constants.DecimalPrecision.unitless)
    let entries: [(String, Bool, Quantity, String)] = [
        ("3/4 + 1/4", true, .rational(UncheckedRational(1, 1).unsafe, .length), "1in"),
        ("2ft + 6in", false, .rational(UncheckedRational(30, 1).unsafe, .length), "2ft 6in"),
        // formattedResult stored with feet, but current options use inches — triggers the ≠ button
        ("18in", false, .rational(UncheckedRational(18, 1).unsafe, .length), "1ft 6in"),
        ("3 × 4", true, .rational(UncheckedRational(12, 1).unsafe, .unitless), "12"),
        ("1.5in × 2in", false, .real(3.0, .area), "3in[2]"),
    ]
    for (input, noUnitsSpecified, quantity, formatted) in entries {
        manager.append(StoredCalculation(
            input: input,
            result: .from(result: EvaluationResult(actualQuantity: quantity, noUnitsSpecified: noUnitsSpecified)),
            formattedResult: formatted
        ))
    }
    return HistoryList(
        historyManager: manager,
        assumeInches: true,
        formattingOptions: options,
        onSelectEntry: { _, _ in print("tapped entry") }
    )
}

#Preview("Empty") {
    let manager = ChronologicalHistoryManager<StoredCalculation>(
        fileURL: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    )
    return HistoryList(
        historyManager: manager,
        assumeInches: true,
        formattingOptions: Quantity.FormattingOptions(.inches, RationalPrecision(denominator: 16), Constants.DecimalPrecision.standard, Constants.DecimalPrecision.unitless),
        onSelectEntry: { _, _ in print("tapped entry") }
    )
}
