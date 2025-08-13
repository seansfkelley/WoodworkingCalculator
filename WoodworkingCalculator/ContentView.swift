import SwiftUI
import ExyteGrid

class Input: ObservableObject {
    enum RawValue {
        case string(String)
        case result(CalculationResult)
    }
    
    @Published
    private var value: RawValue = .string("")
    @AppStorage(Constants.AppStorage.displayInchesOnlyKey)
    private var displayInchesOnly: Bool = Constants.AppStorage.displayInchesOnlyDefault
    @AppStorage(Constants.AppStorage.precisionKey)
    private var precision: Int = Constants.AppStorage.precisionDefault
    
    var stringified: String {
        switch value {
        case .string(let s):
            return s
        case .result(let r):
            let (rational, _) = switch r {
            case .rational(let r):
                r.roundedToPrecision(precision)
            case .real(let r):
                r.toNearestRational(withPrecision: precision)
            }
            return formatAsUsCustomary(rational, displayInchesOnly ? .inches : .feet)
        }
    }
    
    var error: (Int, Double)? {
        switch value {
        case .string:
            return nil
        case .result(let r):
            let (_, error) = switch r {
            case .rational(let r):
                r.roundedToPrecision(precision)
            case .real(let r):
                r.toNearestRational(withPrecision: precision)
            }
            if let e = error {
                return (precision, e)
            } else {
                return nil
            }
        }
    }
    
    var willBackspaceSingleCharacter: Bool {
        return switch value {
        case .string(let s):
            !s.isEmpty
        case .result:
            false
        }
    }
    
    func append(
        _ string: String,
        canReplaceResult: Bool = false,
        deletingSuffix charactersToTrim: Set<Character> = Set()
    ) -> Bool {
        let candidate = {
            if canReplaceResult, case .result = value {
                return string
            } else {
                var s = stringified
                while s.count > 0 && charactersToTrim.contains(s.last.unsafelyUnwrapped) {
                    s.removeLast()
                }
                return (s + string).replacing(/\ +/, with: " ")
            }
        }()
        
        if candidate.wholeMatch(of: /^\s*$/) == nil &&
            candidate != stringified &&
            EvaluatableCalculation.isValidPrefix(candidate)
        {
            value = .string(candidate)
            return true
        } else {
            return false
        }
    }
    
    func backspace() {
        value = switch (value) {
        case .string(let s):
            .string(s.count == 0 ? "" : String(s.prefix(s.count - 1)))
        case .result:
            .string("")
        }
    }
    
    func reset(_ to: RawValue = .string("")) {
        if case let .string(s) = to, !EvaluatableCalculation.isValidPrefix(s)  {
            // nothing
        } else {
            value = to
        }
    }
}

// n.b. this function only works with a valid prefix of a fraction.
private func prettifyInput(_ input: String) -> String {
    return input
        .replacing(/(\d+)\/(\d*)/, with: { match in
            return "\(Int(match.1)!.numerator)⁄\(Int(match.2).map(\.denominator) ?? " ")"
        })
        // Note that this one _specifically_ uses 0-9 instead of \d, because we want to match only
        // those digits that have not been replaced by the above (partial, full) fractionalization
        // because those digits represent in-progress mixed numbers: that is, those with a
        // numerator but no fraction slash.
        .replacing(/([0-9]) ([0-9]|$)/, with: { match in
            return "\(match.1)\u{2002}\(match.2)"
        })
}

private let darkGray = Color.gray.mix(with: .black, by: 0.25)
private let ignorableDenominatorShortcutPrefixes: Set<Character> = [" ", "/"]

struct ContentView: View {
    @State private var previous: String = ""
    @State private var isSettingsPresented: Bool = false
    @State private var isErrorPresented: Bool = false
    @StateObject private var input: Input = Input()
    
    // Why does this have to be a @State? I can't just reassign it as a normal variable?
    @State private var lastBackgroundTime: Date?
    @Environment(\.scenePhase) private var scenePhase
    
    private func append(_ string: String, canReplaceResult: Bool = false, deletingSuffix: Set<Character> = Set()) {
        if input.append(string, canReplaceResult: canReplaceResult, deletingSuffix: deletingSuffix) {
            previous = ""
        }
    }
    
    var body: some View {
        VStack {
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
            Text(prettifyInput(previous))
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
                    input.reset(.string(previous))
                    previous = ""
                    isErrorPresented = false
                }
            HStack {
                if let (precision, error) = input.error {
                    Button(action: { isErrorPresented.toggle() }) {
                        Text("≈")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.orange)
                            .padding(.vertical)
                            .padding(.leading, 8)
                    }
                    .popover(isPresented: $isErrorPresented, arrowEdge: .top) {
                        VStack {
                            Text("Approximation error \(String(format: "%+.3f", error))\"")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer()
                            Text("Rounded to the nearest 1/\(precision)\"")
                                .font(.system(.callout))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .presentationCompactAdaptation(.popover)
                    }
                }
                Text(prettifyInput(input.stringified))
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
                    // Branching inside the component instead of outside to make two distinct ones
                    // is a little inelegant but I specifically want to keep the button instance
                    // the same so the stateful on-press color-change animation doesn't abruptly
                    // end while you're actively long-pressing the button due to changed identity.
                    CalculatorButton(.text(input.willBackspaceSingleCharacter ? "⌫" : "C"), .gray) {
                        previous = ""
                        isErrorPresented = false
                        input.backspace()
                    }
                    .simultaneousGesture(LongPressGesture(minimumDuration: 1).onEnded { _ in
                        previous = ""
                        isErrorPresented = false
                        input.reset()
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
                    CalculatorButton(.text("'"), .gray) { append("'", canReplaceResult: true) }
                    CalculatorButton(.text("\""), .gray) { append("\"", canReplaceResult: true) }
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
                    CalculatorButton(.text("⁄"), .gray) {
                        append("/", deletingSuffix: ignorableDenominatorShortcutPrefixes)
                    }
                }
                GridGroup {
                    CalculatorButton(.text("⁄₂"), .gray) {
                        append("/2", deletingSuffix: ignorableDenominatorShortcutPrefixes)
                    }
                    CalculatorButton(.text("⁄₄"), .gray) {
                        append("/4", deletingSuffix: ignorableDenominatorShortcutPrefixes)
                    }
                    CalculatorButton(.text("⁄₈"), .gray) {
                        append("/8", deletingSuffix: ignorableDenominatorShortcutPrefixes)
                    }
                    CalculatorButton(.text("⁄₁₆"), .gray) {
                        append("/16", deletingSuffix: ignorableDenominatorShortcutPrefixes)
                    }
                }
            }
        }
        .padding()
        .onChange(of: scenePhase, { oldPhase, newPhase in
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
                input.reset()
                previous = ""
                isErrorPresented = false
                isSettingsPresented = false
            } else if newPhase == .background {
                lastBackgroundTime = Date()
            } else {
                // don't care
            }
        })
    }
    
    private func evaluate() {
        let inputString = input.stringified
        let result = EvaluatableCalculation.from(inputString)?.evaluate()
        guard let result else {
            return
        }

        previous = inputString.trimmingCharacters(in: CharacterSet.whitespaces)
        input.reset(.result(result))
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
