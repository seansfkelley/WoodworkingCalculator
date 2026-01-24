import SwiftUI
import OSLog

private let logger = Logger(subsystem: "WoodworkingCalculator", category: "ContentView")
private let horizontalSpacing = 12
private let gridSpacing = 8

struct ContentView: View {
    private var history = ChronologicalHistoryManager<StoredCalculation>(fileURL: .applicationSupportDirectory.appendingPathComponent("history.json"))

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
            Constants.decimalDigitsOfPrecision,
            Constants.decimalDigitsOfPrecisionUnitless,
        )
    }

    private func append(_ string: String, canReplaceResult: Bool = false, trimmingSuffix: TrimmableCharacterSet? = nil) {
        if let newInput = input.appending(
            suffix: string,
            formattingResultWith: formattingOptions,
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
        VStack {
            HStack {
                Button(action: { isSettingsPresented.toggle() }) {
                    Image(systemName: "gear")
                        .font(.system(size: 24))
                        .foregroundStyle(.orange)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .sheet(isPresented: $isSettingsPresented) {
                    Settings()
                        .background(.windowBackground)
                        .presentationDetents([.medium])
                }
                Button(action: { isHistoryPresented.toggle() }) {
                    Image(systemName: "clock")
                        .font(.system(size: 24))
                        .foregroundStyle(.orange)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .sheet(isPresented: $isHistoryPresented) {
                    HistoryList(
                        historyManager: history,
                        formattingOptions: formattingOptions,
                        onSelectEntry: {
                            previous = .init($0)
                            input = .result($1)
                            appendHistoryEntry($0, $1)
                        }
                    )
                        .background(.windowBackground)
                        .presentationDetents([.medium, .large])
                }
                Spacer()

                Menu {
                    // Unfortunately it does not seem possible to right-align text in a Menu, so
                    // we live with this rather awkward jagged-edge arrangement.
                    switch input {
                    case .result(let quantity):
                        Section("Metric Conversions") {
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
                        .font(.system(size: 24))
                        .foregroundStyle(.orange)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
            }
            // I have no idea why this HStack or the buttons in it seem to have a few more pixels of
            // horizontal padding, which we compensate for here by not padding it out as much as the
            // content below. The choice of `gridSpacing` is actually NOT significant except that it
            // seems to be the right number empirically and maybe there's something to that.
            .padding(.horizontal, CGFloat(gridSpacing))
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
                .padding(.horizontal, CGFloat(horizontalSpacing))
            ResultReadout(
                input: input,
                formattingOptions: formattingOptions,
                isErrorPresented: $isErrorPresented,
                isRoundingErrorWarningPresented: $isRoundingErrorWarningPresented,
                shakeError: $shakeError,
                openSettings: {
                    isRoundingErrorWarningPresented = false
                    isSettingsPresented = true
                }
            )
            .padding(.horizontal, CGFloat(horizontalSpacing))
            let backspaced: ValidExpressionPrefix? = switch input {
            case .draft(let prefix, _): prefix.backspaced
            case .result: nil
            }
            ButtonGrid(
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
                evaluate: evaluate,
            )
            // Grid applies padding to the edges too, not just between items, so compensate here.
            .padding(.horizontal, CGFloat(horizontalSpacing - gridSpacing))
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
    }

    private func evaluate() {
        isErrorPresented = false
        isRoundingErrorWarningPresented = false

        let rawString = switch input {
        case .draft(let prefix, _): prefix.value
        case .result(let quantity): quantity.formatted(with: formattingOptions).0
        }

        let missingParens = EvaluatableCalculation.countMissingTrailingParens(rawString)
        let cleanedInputString = rawString.trimmingCharacters(in: CharacterSet.whitespaces) + String(repeating: ")", count: missingParens)
        let calculation = EvaluatableCalculation.from(cleanedInputString)
        guard let calculation else {
            // silently nop until they finish what they were doing
            return
        }

        switch calculation.evaluate() {
        case .success(let quantity):
            let dimensionedQuantity = if assumeInches && quantity.dimension == .unitless && calculation.allDimensionsAreUnitless {
                quantity.withDimension(.length)
            } else {
                quantity
            }
            input = .result(dimensionedQuantity)
            previous = .init(cleanedInputString)
            appendHistoryEntry(cleanedInputString, dimensionedQuantity)
        case .failure(let error):
            input = .draft(.init(rawString)!, error)
            shakeError = true
        }
    }

    private func appendHistoryEntry(_ input: String, _ result: Quantity) {
        let formattedResult = result.formatted(with: formattingOptions).0
        if let last = history.entries.last, last.data.input == input && last.data.formattedResult == formattedResult {
            logger.info("not adding redundant history entry")
            return
        }
        history.append(
            .init(
                input: input,
                result: .from(quantity: result),
                formattedResult: result.formatted(with: formattingOptions).0,
            ),
        )
    }
}

struct CalculatorButton: View {
    enum Content {
        case text(String)
        case image(String)
    }
    
    let content: Content
    let fill: Color
    let contentOffset: CGPoint
    let action: () -> Void


    init(_ content: Content, _ fill: Color, contentOffset: CGPoint = CGPoint(), action: @escaping () -> Void) {
        self.content = content
        self.fill = fill
        self.contentOffset = contentOffset
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            switch content {
            case .text(let text):
                Text(text)
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(x: contentOffset.x, y: contentOffset.y)
            case .image(let image):
                Image(systemName: image)
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(x: contentOffset.x, y: contentOffset.y)
            }
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: .infinity))
        .tint(fill)
    }
}

struct DimensionButton: View {
    let dimension: Dimension
    let unit: UsCustomaryUnit
    let onSelect: (String) -> Void
    
    init(_ unit: UsCustomaryUnit, _ dimension: Dimension, onSelect: @escaping (String) -> Void) {
        self.unit = unit
        self.dimension = dimension
        self.onSelect = onSelect
    }
    
    private var systemImage: String? {
        switch dimension {
        case .length: "line.diagonal"
        case .area: "square"
        case .volume: "cube"
        default: nil
        }
    }

    var body: some View {
        let formatted = dimension.formatted(withUnit: unit.abbreviation)
        Button {
            onSelect(formatted)
        } label: {
            if let systemImage {
                Label(formatted.withPrettyNumbers, systemImage: systemImage)
            } else {
                Text(formatted.withPrettyNumbers)
            }
        }
    }
}

#Preview {
    ContentView()
}
