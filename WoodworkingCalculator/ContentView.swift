import SwiftUI
import ExyteGrid

private func appendTrailingParentheses(to string: String) -> AttributedString {
    var attributedString = AttributedString(string)

    let missingParentheses = EvaluatableCalculation.countMissingTrailingParens(string)
    if missingParentheses > 0 {
        var trailingParens = AttributedString(String(repeating: ")", count: missingParentheses))
        trailingParens.foregroundColor = .secondary
        attributedString.append(trailingParens)
    }

    return attributedString
}

private let darkGray = Color.gray.mix(with: .black, by: 0.25)
private let ignorableDenominatorShortcutPrefixes: Set<Character> = [" ", "/"]

struct ContentView: View {
    @State private var previous: ValidExpressionPrefix?
    @State private var isSettingsPresented = false
    @State private var isInaccuracyWarningPresented = false
    @State private var isErrorPresented = false
    @State private var shakeError = false
    @StateObject private var input = InputValue()

    // Why does this have to be a @State? I can't just reassign it as a normal variable?
    @State private var lastBackgroundTime: Date?
    @Environment(\.scenePhase) private var scenePhase
    
    private func append(_ string: String, canReplaceResult: Bool = false, trimmingSuffix: TrimmableCharacterSet? = nil) {
        if input.append(string, canReplaceResult: canReplaceResult, trimmingSuffix: trimmingSuffix) {
            previous = nil
            isInaccuracyWarningPresented = false
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
                    if let meters = input.meters {
                        Section("Metric Conversions") {
                            Text("= \(meters.formatAsDecimal(toPlaces: 3)) m")
                            Text("= \((meters * 100).formatAsDecimal(toPlaces: 2)) cm")
                            Text("= \((meters * 1000).formatAsDecimal(toPlaces: 1)) mm")
                        }
                    } else {
                        Section("Metric Operations") {
                            Button(action: { append("m") }) { Text("insert \"m\"") }
                            Button(action: { append("cm") }) { Text("insert \"cm\"") }
                            Button(action: { append("mm") }) { Text("insert \"mm\"") }
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
                    input.setValue(to: previous.map { .draft($0, nil) })
                    previous = nil
                    isInaccuracyWarningPresented = false
                    isErrorPresented = false
                }
            HStack {
                if let error = input.error {
                    Button(action: { isErrorPresented.toggle() }) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundStyle(.red)
                            .padding(.vertical)
                            .padding(.leading, 8)
                            .offset(x: shakeError ? 20 : 0)
                    }
                    .popover(isPresented: $isErrorPresented, arrowEdge: .top) {
                        Text(error.localizedDescription)
                            .font(.system(.body))
                            .padding()
                            .fixedSize(horizontal: false, vertical: true)
                            .presentationCompactAdaptation(.popover)
                    }
                } else if let (denominator, inaccuracy, dimension) = input.inaccuracy {
                    Button(action: { isInaccuracyWarningPresented.toggle() }) {
                        Text("≈")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.orange)
                            .padding(.vertical)
                            .padding(.leading, 8)
                    }
                    .popover(isPresented: $isInaccuracyWarningPresented, arrowEdge: .top) {
                        VStack {
                            let formatted = prettyPrintExpression("\(String(format: "%+.3f", inaccuracy))\(dimension.formatted(withUnit: "in"))")
                            Text("Rounding error: \(formatted))")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer()
                            Text("""
                                actual \
                                \(formatted) \
                                = \
                                \(prettyPrintExpression(input.draft.value))
                                """)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Divider()
                            Text("Rounded to the nearest 1/\(denominator)\"")
                                .font(.system(.callout))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .presentationCompactAdaptation(.popover)
                    }
                }
                Text(appendTrailingParentheses(to: prettyPrintExpression(input.draft.value)))
                    .frame(
                        minWidth: 0,
                        maxWidth:  .infinity,
                        minHeight: 100,
                        maxHeight: 100,
                        alignment: .trailing
                    )
                    .font(.system(size: 100, weight: .light))
                    .truncateWithFade(width: 0.1, startingAt: 0.05)
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .truncationMode(.head)
                    .textSelection(.enabled)
                    .accessibilityIdentifier("readout")
            }
            Grid(tracks: 4, spacing: 8) {
                // n.b. GridGroup is only to work around limitations in SwiftUI's ViewBuilder
                // closure typings, but I figured it doubled as a nice way to emphasize the rows.
                GridGroup {
                    CalculatorButton(.text(input.backspaced.buttonText), .gray) {
                        previous = nil
                        isInaccuracyWarningPresented = false
                        isErrorPresented = false
                        input.setValue(to: input.backspaced.rawValue)
                    }
                    .simultaneousGesture(LongPressGesture(minimumDuration: 1).onEnded { _ in
                        previous = nil
                        isInaccuracyWarningPresented = false
                        isErrorPresented = false
                        input.setValue(to: nil)
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
                input.setValue(to: nil)
                previous = nil
                isInaccuracyWarningPresented = false
                isErrorPresented = false
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
        let inputString = input.draft.value
        let missingParens = EvaluatableCalculation.countMissingTrailingParens(inputString)
        let formattedInputString = inputString.trimmingCharacters(in: CharacterSet.whitespaces) + String(repeating: ")", count: missingParens)
        let result = EvaluatableCalculation.from(formattedInputString)?.evaluate()
        guard let result else {
            return
        }
        
        switch result {
        case .success(let answer):
            previous = .init(formattedInputString)
            input.setValue(to: .result(answer))
        case .failure(let error):
            input.setValue(to: .draft(input.draft, error))
            shakeError = true
        }
        
        isInaccuracyWarningPresented = false
        isErrorPresented = false
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
