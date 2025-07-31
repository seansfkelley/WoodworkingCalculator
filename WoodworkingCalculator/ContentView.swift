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
    
    func append(_ string: String, replaceResult: Bool = false) -> Bool {
        let candidate: String? = {
            if replaceResult, case .result = value {
                if string != " " {
                    return string
                }
            } else {
                let s = stringified
                if string != " " || (s.count > 0 && s.last != " ") {
                    return s + string
                }
            }
            return nil
        }()
        
        if candidate != nil && EvaluatableCalculation.isValidPrefix(candidate!) {
            value = .string(candidate!)
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
    return input.replacing(/(\d+)\/(\d*)/, with: { match in
        return "\(Int(match.1)!.numerator)⁄\(Int(match.2).map(\.denominator) ?? " ")"
    })
}

private let darkGray = Color.gray.mix(with: .black, by: 0.25)

struct ContentView: View {
    @State private var previous: String = ""
    @State private var isSettingsPresented: Bool = false
    @State private var isErrorPresented: Bool = false
    @StateObject private var input: Input = Input()
    
    private func append(_ string: String, replaceResult: Bool = false) {
        if input.append(string, replaceResult: replaceResult) {
            previous = ""
        }
    }
    
    private func appendToleratingPrefix(_ preexistingPrefix: String, _ suffix: String) {
        if input.stringified.hasSuffix(preexistingPrefix) && input.append(suffix) {
            previous = ""
        } else if input.append(preexistingPrefix + suffix) {
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
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.secondary)
                .minimumScaleFactor(0.3)
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
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
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
                    CalculatorButton(.text("("), .gray, contentOffset: CGPoint(x: -2, y: -2)) { append("(", replaceResult: true) }
                    CalculatorButton(.text(")"), .gray, contentOffset: CGPoint(x: 2, y: -2)) { append(")", replaceResult: true) }
                    CalculatorButton(.image("divide"), .orange) { append("÷") }
                }
                GridGroup {
                    CalculatorButton(.text("'"), .gray) { append("'", replaceResult: true) }
                    CalculatorButton(.text("\""), .gray) { append("\"", replaceResult: true) }
                    CalculatorButton(.text("."), .gray) { append(".", replaceResult: true) }
                    CalculatorButton(.image("multiply"), .orange) { append("×") }
                }
                GridGroup {
                    CalculatorButton(.text("7"), darkGray) { append("7", replaceResult: true) }
                    CalculatorButton(.text("8"), darkGray) { append("8", replaceResult: true) }
                    CalculatorButton(.text("9"), darkGray) { append("9", replaceResult: true) }
                    CalculatorButton(.image("minus"), .orange) { append("-") }
                }
                GridGroup {
                    CalculatorButton(.text("4"), darkGray) { append("4", replaceResult: true) }
                    CalculatorButton(.text("5"), darkGray) { append("5", replaceResult: true) }
                    CalculatorButton(.text("6"), darkGray) { append("6", replaceResult: true) }
                    CalculatorButton(.image("plus"), .orange) { append("+") }
                }
                GridGroup {
                    CalculatorButton(.text("1"), darkGray) { append("1", replaceResult: true) }
                    CalculatorButton(.text("2"), darkGray) { append("2", replaceResult: true) }
                    CalculatorButton(.text("3"), darkGray) { append("3", replaceResult: true) }
                }
                CalculatorButton(.image("equal"), .orange) { evaluate() }.gridSpan(row: 2)
                GridGroup {
                    CalculatorButton(.text("⁄"), .gray) { append("/") }
                    CalculatorButton(.text("0"), darkGray) { append("0", replaceResult: true) }
                    CalculatorButton(.text("␣"), .gray) { append(" ", replaceResult: true) }
                }
                GridGroup {
                    CalculatorButton(.text("⁄₂"), .gray) { appendToleratingPrefix("/", "2") }
                    CalculatorButton(.text("⁄₄"), .gray) { appendToleratingPrefix("/", "4") }
                    CalculatorButton(.text("⁄₈"), .gray) { appendToleratingPrefix("/", "8") }
                    CalculatorButton(.text("⁄₁₆"), .gray) { appendToleratingPrefix("/", "16") }
                }
            }
        }
        .padding()
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
