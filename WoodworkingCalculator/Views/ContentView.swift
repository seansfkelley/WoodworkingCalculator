import SwiftUI
import OSLog

private let logger = Logger(subsystem: "WoodworkingCalculator", category: "ContentView")
private let horizontalSpacing: CGFloat = 12
private let gridSpacing: CGFloat = 8

struct ContentView: View {
    private var history = ChronologicalHistoryManager<StoredCalculation>(fileURL: .applicationSupportDirectory.appendingPathComponent("history.jsonl"))

    @State private var previous: ValidExpressionPrefix?
    @State private var isSettingsPresented = false
    @State private var isHistoryPresented = false
    @State private var isErrorPresented = false
    @State private var isRoundingErrorWarningPresented = false
    @State private var shakeError = false
    @State private var input = InputValue.draft(.init(), nil)

    // Why does this have to be a @State? I can't just reassign it as a normal variable?
    @State private var lastBackgroundTime: Date?
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(Constants.AppStorage.displayInchesOnlyKey)
    private var displayInchesOnly = Constants.AppStorage.displayInchesOnlyDefault
    @AppStorage(Constants.AppStorage.precisionKey)
    private var precision = Constants.AppStorage.precisionDefault
    @AppStorage(Constants.AppStorage.assumeInchesKey)
    private var assumeInches = Constants.AppStorage.assumeInchesDefault

    private var formattingOptions: Quantity.FormattingOptions {
        .init(
            displayInchesOnly ? .inches : .feet,
            precision,
            Constants.DecimalPrecision.standard,
            Constants.DecimalPrecision.unitless,
        )
    }

    private func append(_ string: String, canReplaceResult: Bool = false, trimmingSuffix: TrimmableCharacterSet? = nil) {
        if let newInput = input.appending(
            suffix: string,
            formattingResultWith: formattingOptions,
            assumeInches: assumeInches,
            allowingResultReplacement: canReplaceResult,
            trimmingSuffix: trimmingSuffix,
        ) {
            input = newInput
            previous = nil
            isRoundingErrorWarningPresented = false
            isErrorPresented = false
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Text((previous?.value ?? "").withPrettyNumbers)
                    .frame(
                        minWidth: 0,
                        maxWidth:  .infinity,
                        minHeight: 40,
                        maxHeight: 40,
                        alignment: .trailing
                    )
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                    .truncateWithFade(width: 0.1, startingAt: 0.1)
                    .lineLimit(1)
                    .truncationMode(.head)
                    .onTapGesture {
                        if let previous {
                            input = .draft(previous, nil)
                            self.previous = nil
                            isErrorPresented = false
                            isRoundingErrorWarningPresented = false
                        }
                    }
                    .padding(.horizontal, horizontalSpacing)
                ResultReadout(
                    input: input,
                    assumeInches: assumeInches,
                    formattingOptions: formattingOptions,
                    isErrorPresented: $isErrorPresented,
                    isRoundingErrorWarningPresented: $isRoundingErrorWarningPresented,
                    shakeError: $shakeError,
                    openSettings: {
                        isRoundingErrorWarningPresented = false
                        isSettingsPresented = true
                    }
                )
                .padding(.horizontal, horizontalSpacing)
                let backspaced: ValidExpressionPrefix? = switch input {
                case .draft(let prefix, _): prefix.backspaced
                case .result: nil
                }
                ButtonGrid(
                    spacing: gridSpacing,
                    backspacedInput: backspaced,
                    resetInput: {
                        previous = nil
                        isErrorPresented = false
                        isRoundingErrorWarningPresented = false
                        input = .draft($0, nil)
                    },
                    append: { string, canReplaceResult, trimmingSuffix in
                        append(string, canReplaceResult: canReplaceResult, trimmingSuffix: trimmingSuffix)
                    },
                    invert: invert,
                    evaluate: evaluate,
                )
                .padding(.horizontal, horizontalSpacing)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { isSettingsPresented.toggle() }) {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { isHistoryPresented.toggle() }) {
                        Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        // Unfortunately it does not seem possible to right-align text in a Menu, so
                        // we live with this rather awkward jagged-edge arrangement.
                        switch input {
                        case .result(let result):
                            Section("Metric Conversions") {
                                let quantity = result.quantity(assumingLengthIf: assumeInches)
                                if let meters = quantity.meters {
                                    Text("= \(meters.formatAsDecimal(toPlaces: 3)) \(quantity.dimension.formatted(withUnit: "m"))".withPrettyNumbers)
                                    Text("= \((meters * 100 ^^ quantity.dimension).formatAsDecimal(toPlaces: 2)) \(quantity.dimension.formatted(withUnit: "cm"))".withPrettyNumbers)
                                    Text("= \((meters * 1000 ^^ quantity.dimension).formatAsDecimal(toPlaces: 1)) \(quantity.dimension.formatted(withUnit: "mm"))".withPrettyNumbers)
                                } else {
                                    Text("Unitless values cannot be converted.")
                                }
                            }
                        case .draft(let prefix, _):
                            // Use "mm" and not just "m" because if there is already a trailing "m",
                            // appending a single "m" would actually create a valid unit. o_O
                            let valid = EvaluatableCalculation.isValidPrefix(prefix.value + "mm")
                            Section("Insert Metric Unit") {
                                Button(action: { append("m") }) { Text("insert \"m\"") }.disabled(!valid)
                                Button(action: { append("cm") }) { Text("insert \"cm\"") }.disabled(!valid)
                                Button(action: { append("mm") }) { Text("insert \"mm\"") }.disabled(!valid)
                            }
                        }
                    } label: {
                        Image(systemName: "ruler")
                    }
                }
            }
        }
        .sheet(isPresented: $isSettingsPresented) {
            Settings()
                .background(.windowBackground)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $isHistoryPresented) {
            HistoryList(
                historyManager: history,
                assumeInches: assumeInches,
                formattingOptions: formattingOptions,
                onSelectEntry: {
                    previous = .init($0)
                    input = .result($1)
                    appendHistoryEntryIfDifferent($0, $1)
                }
            )
                .background(.windowBackground)
                .presentationDetents([.medium, .large])
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // It seems like when foregrounding/backgrounding the app, it always bounces through
            // the inactive state. By clearing the state before we're fully active, we avoid a
            // flash of the old state being visible when the app reopens.
            //
            // There still seems to be a brief fadeout, but I think this is from iOS smoothing the
            // visual transition from a screenshot of the last-known state to what the app looks
            // like at the time it's foregrounded. Polish would skip this transition if possible,
            // but I'm not sure how.
            if oldPhase == .background &&
                newPhase == .inactive &&
                lastBackgroundTime != nil &&
                Date().timeIntervalSince(lastBackgroundTime!) > 30 * 60
            {
                input = .draft(.init(), nil)
                previous = nil
                isErrorPresented = false
                isRoundingErrorWarningPresented = false
                isSettingsPresented = false
            } else if newPhase == .background {
                lastBackgroundTime = Date()
            } else {
                // don't care
            }
        }
        .onChange(of: shakeError) { _, newValue in
            // Adapted from https://stackoverflow.com/questions/72795306/how-can-make-a-shake-effect-in-swiftui
            if newValue {
                withAnimation(Animation.spring(response: 0.2, dampingFraction: 0.3, blendDuration: 0.2)) {
                    shakeError = false
                }
            }
        }
        .onChange(of: isSettingsPresented) { _, isShowing in
            guard !isShowing else { return }

            // This is a little hacky in that there is no type-level guarantee that this result
            // came from previous, but I mean, we know how all this stuff works so it's fine.
            if case .result(let result) = input, let previous {
                appendHistoryEntryIfDifferent(previous.value, result)
            }
        }
    }

    private func invert() {
        if let inverted = input.inverted(formattingResultWith: formattingOptions, assumeInches: assumeInches) {
            input = inverted
        }
    }

    private func evaluate() {
        isErrorPresented = false
        isRoundingErrorWarningPresented = false

        let rawString = switch input {
        case .draft(let prefix, _): prefix.value
        case .result(let result): result.quantity(assumingLengthIf: assumeInches).formatted(with: formattingOptions).0
        }

        let missingParens = EvaluatableCalculation.countMissingTrailingParens(rawString)
        let cleanedInputString = rawString.trimmingCharacters(in: CharacterSet.whitespaces) + String(repeating: ")", count: missingParens)
        let calculation = EvaluatableCalculation.from(cleanedInputString)
        guard let calculation else {
            // silently nop until they finish what they were doing
            return
        }

        switch calculation.evaluate() {
        case .success(let result):
            input = .result(result)
            previous = .init(cleanedInputString)
            appendHistoryEntryIfDifferent(cleanedInputString, result)
        case .failure(let error):
            input = .draft(.init(rawString)!, error)
            shakeError = true
        }
    }

    private func appendHistoryEntryIfDifferent(_ input: String, _ result: EvaluationResult) {
        let displayQuantity = result.quantity(assumingLengthIf: assumeInches)
        let formattedResult = displayQuantity.formatted(with: formattingOptions).0
        if let last = history.entries.last, last.data.input == input && last.data.formattedResult == formattedResult {
            logger.info("not adding redundant history entry")
            return
        }
        history.append(
            .init(
                input: input,
                result: .from(result: result),
                formattedResult: formattedResult,
            ),
        )
    }
}

#Preview {
    ContentView()
}
