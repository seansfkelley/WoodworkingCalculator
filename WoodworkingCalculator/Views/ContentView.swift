import SwiftUI
import ExyteGrid

private let darkGray = Color.gray.mix(with: .black, by: 0.25)
private let ignorableDenominatorShortcutPrefixes: Set<Character> = [" ", "/"]

struct ContentView: View {
    @State private var previous: ValidExpressionPrefix?
    @State private var isSettingsPresented = false
    @State private var isErrorPresented = false
    @State private var isRoundingErrorWarningPresented = false
    @State private var shakeError = false
    @State private var input = InputValue.draft(.init(), nil)

    // Why does this have to be a @State? I can't just reassign it as a normal variable?
    @State private var lastBackgroundTime: Date?
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(Constants.AppStorage.displayInchesOnlyKey)
    private var displayInchesOnly: Bool = Constants.AppStorage.displayInchesOnlyDefault
    @AppStorage(Constants.AppStorage.precisionKey)
    private var precision: RationalPrecision = Constants.AppStorage.precisionDefault

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
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 32))
                        .foregroundStyle(.orange)
                }
                .sheet(isPresented: $isSettingsPresented) {
                    Settings()
                        .presentationDetents([.medium])
                }
                Spacer()

                Menu {
                    // Unfortunately it does not seem possible to right-align text in a Menu, so
                    // we live with this rather awkward jagged-edge arrangement.
                    switch input {
                    case .result(let quantity):
                        Section("Metric Conversions") {
                            if let meters = quantity.meters {
                                Text("= \(meters.formatAsDecimal(toPlaces: 3)) m")
                                Text("= \((meters * 100).formatAsDecimal(toPlaces: 2)) cm")
                                Text("= \((meters * 1000).formatAsDecimal(toPlaces: 1)) mm")
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
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .font(.system(size: 32))
                        .foregroundStyle(.orange)
                }
            }
            Text(prettyPrintExpression(previous?.value ?? ""))
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
            ResultReadout(
                input: input,
                formattingOptions: formattingOptions,
                isErrorPresented: $isErrorPresented,
                isRoundingErrorWarningPresented: $isRoundingErrorWarningPresented,
                shakeError: $shakeError,
            )
            Grid(tracks: 4, spacing: 8) {
                // n.b. GridGroup is only to work around limitations in SwiftUI's ViewBuilder
                // closure typings, but I figured it doubled as a nice way to emphasize the rows.
                GridGroup {
                    CalculatorButton(.text(input.backspaced.buttonText), .gray) {
                        previous = nil
                        isErrorPresented = false
                        isRoundingErrorWarningPresented = false
                        input = input.backspaced.inputValue
                    }
                    .simultaneousGesture(LongPressGesture(minimumDuration: 1).onEnded { _ in
                        previous = nil
                        isErrorPresented = false
                        isRoundingErrorWarningPresented = false
                        input = .draft(.init(), nil)
                    })
                    CalculatorButton(.text("("), .gray, contentOffset: CGPoint(x: -2, y: -2)) {
                        append("(", canReplaceResult: true)
                    }
                    CalculatorButton(.text(")"), .gray, contentOffset: CGPoint(x: 2, y: -2)) {
                        append(")")
                    }
                    CalculatorButton(.image("divide"), .orange) { append("÷") }
                }
                GridGroup {
                    CalculatorButton(.text("'"), .gray) { append("ft") }
                    CalculatorButton(.text("\""), .gray) { append("in") }
                    CalculatorButton(.text("."), .gray) { append(".", canReplaceResult: true) }
                    CalculatorButton(.image("multiply"), .orange) { append("×") }
                }
                GridGroup {
                    CalculatorButton(.text("7"), darkGray) { append("7", canReplaceResult: true) }
                    CalculatorButton(.text("8"), darkGray) { append("8", canReplaceResult: true) }
                    CalculatorButton(.text("9"), darkGray) { append("9", canReplaceResult: true) }
                    CalculatorButton(.image("minus"), .orange) { append("-") }
                }
                GridGroup {
                    CalculatorButton(.text("4"), darkGray) { append("4", canReplaceResult: true) }
                    CalculatorButton(.text("5"), darkGray) { append("5", canReplaceResult: true) }
                    CalculatorButton(.text("6"), darkGray) { append("6", canReplaceResult: true) }
                    CalculatorButton(.image("plus"), .orange) { append("+") }
                }
                GridGroup {
                    CalculatorButton(.text("1"), darkGray) { append("1", canReplaceResult: true) }
                    CalculatorButton(.text("2"), darkGray) { append("2", canReplaceResult: true) }
                    CalculatorButton(.text("3"), darkGray) { append("3", canReplaceResult: true) }
                }
                CalculatorButton(.image("equal"), .orange) { evaluate() }.gridSpan(row: 2)
                GridGroup {
                    CalculatorButton(.text("␣"), .gray) { append(" ", canReplaceResult: true) }
                    CalculatorButton(.text("0"), darkGray) { append("0", canReplaceResult: true) }
                    CalculatorButton(.text("⁄"), .gray) { append("/", trimmingSuffix: .whitespaceAndFractionSlash) }
                }
                GridGroup {
                    CalculatorButton(.text("⁄₂"), .gray) { append("/2", trimmingSuffix: .whitespaceAndFractionSlash) }
                    CalculatorButton(.text("⁄₄"), .gray) { append("/4", trimmingSuffix: .whitespaceAndFractionSlash) }
                    CalculatorButton(.text("⁄₈"), .gray) { append("/8", trimmingSuffix: .whitespaceAndFractionSlash) }
                    CalculatorButton(.text("⁄₁₆"), .gray) { append("/16", trimmingSuffix: .whitespaceAndFractionSlash) }
                }
            }
        }
        .padding()
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
                Date().timeIntervalSince(lastBackgroundTime!) > 30 * 60 {
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
        let result = EvaluatableCalculation.from(cleanedInputString)?.evaluate()
        guard let result else {
            input = .draft(.init(rawString)!, .syntaxError)
            shakeError = true
            return
        }

        switch result {
        case .success(let quantity):
            input = .result(quantity)
            previous = .init(cleanedInputString)
        case .failure(let error):
            input = .draft(.init(rawString)!, error)
            shakeError = true
        }
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
                    .font(.system(size: 32))
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



#Preview {
    ContentView()
}
