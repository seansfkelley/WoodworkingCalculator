import SwiftUI

enum InputValue {
    case string(String)
    case result(Rational, Double?)
}

struct Input: CustomStringConvertible {
    private var value: InputValue = .string("")
    @AppStorage(Constants.AppStorage.displayInchesOnlyKey) private var displayInchesOnly: Bool = Constants.AppStorage.displayInchesOnlyDefault
    
    mutating func set(_ value: InputValue) {
        self.value = value
    }
    
    mutating func append(_ string: String, replaceResult: Bool = false) -> Bool {
        let candidate: String? = {
            if replaceResult, case .result = value {
                if string != " " {
                    return string
                }
            } else {
                let stringified = description
                if string != " " || stringified.last != " " {
                    return stringified + string
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
    
    mutating func backspace() {
        let stringified = description
        value = .string(stringified.count == 0 ? "" : String(stringified.prefix(stringified.count - 1)))
    }
    
    var description: String {
        return switch value {
        case .string(let s):
            s
        case .result(let f, _):
            formatAsUsCustomary(f, displayInchesOnly ? .inches : .feet)
        }
    }
    
    var error: Double? {
        return switch value {
        case .string:
            nil
        case .result(_, let e):
            e
        }
    }
    
    var backspaceable: Bool {
        return switch value {
        case .string(let s):
            !s.isEmpty
        case .result:
            false
        }
    }
}

struct ContentView: View {
    @State private var previous: String = ""
    @State private var isSettingsPresented: Bool = false
    @State private var isErrorPresented: Bool = false
    @State private var input: Input = Input()
    @AppStorage(Constants.AppStorage.displayInchesOnlyKey) private var displayInchesOnly: Bool = Constants.AppStorage.displayInchesOnlyDefault
    @AppStorage(Constants.AppStorage.precisionKey) private var precision: Int = Constants.AppStorage.precisionDefault
    
    private func append(_ string: String, replaceResult: Bool = false) {
        if input.append(string, replaceResult: replaceResult) {
            previous = ""
        }
    }
    
    private func appendToleratingPrefix(_ preexistingPrefix: String, _ suffix: String) {
        if input.description.hasSuffix(preexistingPrefix) && input.append(suffix) {
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
            Text(previous)
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
                    input.set(.string(previous))
                    previous = ""
                    isErrorPresented = false
                }
            HStack {
                if input.error != nil {
                    Button(action: { isErrorPresented.toggle() }) {
                        Text("≈")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.red)
                            .padding()
//                            .overlay(Circle().stroke(.red, lineWidth: 4))
                    }
                    .popover(isPresented: $isErrorPresented, arrowEdge: .top) {
                        VStack {
                            Text("Approximation error \(String(format: "%+.3f", input.error!))\"")
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
                // This is how you'd replace the space with another character with different styling.
//                let formattedString: AttributedString = input.description
//                    .split(separator: " ", omittingEmptySubsequences: false)
//                    .reduce(into: AttributedString()) { accumulator, s in
//                        if accumulator.characters.count > 0 {
////                            var space = AttributedString(" ")
////                            space.underlineStyle = .single
////                            space.underlineColor = .lightGray
//                            var space = AttributedString("_")
//                            space.foregroundColor = .lightGray
//                            accumulator.append(space)
//                        }
//                        accumulator.append(AttributedString(s))
//                    }
                
                Text(input.description)
                    .frame(
                        minWidth: 0,
                        maxWidth:  .infinity,
                        minHeight: 100,
                        maxHeight: 100,
                        alignment: .trailing
                    )
                    .font(.system(size: 100, weight: .light))
                    .minimumScaleFactor(0.3)
            }
            HStack {
                // Branching inside the component instead of outside to make two distinct ones
                // is a little inelegant but I specifically want to keep the button instance
                // the same so the stateful on-press color-change animation doesn't abruptly
                // end while you're actively long-pressing the button due to a change in identity.
                CircleButton(.text(input.backspaceable ? "⌫" : "C"), .gray) {
                    previous = ""
                    isErrorPresented = false
                    
                    if input.backspaceable {
                        input.backspace()
                    } else {
                        input.set(.string(""))
                    }
                }
                .simultaneousGesture(LongPressGesture(minimumDuration: 1).onEnded { _ in
                    previous = ""
                    isErrorPresented = false
                    input.set(.string(""))
                })
                CircleButton(.text("'"), .gray) { append("'", replaceResult: true) }
                CircleButton(.text("\""), .gray) { append("\"", replaceResult: true) }
                CircleButton(.image("divide"), .orange) { append("/") }
            }
            HStack {
                CircleButton(.text("7"), .gray) { append("7", replaceResult: true) }
                CircleButton(.text("8"), .gray) { append("8", replaceResult: true) }
                CircleButton(.text("9"), .gray) { append("9", replaceResult: true) }
                CircleButton(.image("multiply"), .orange) { append("×") }
            }
            HStack {
                CircleButton(.text("4"), .gray) { append("4", replaceResult: true) }
                CircleButton(.text("5"), .gray) { append("5", replaceResult: true) }
                CircleButton(.text("6"), .gray) { append("6", replaceResult: true) }
                CircleButton(.image("minus"), .orange) { append("-") }
            }
            HStack {
                CircleButton(.text("1"), .gray) { append("1", replaceResult: true) }
                CircleButton(.text("2"), .gray) { append("2", replaceResult: true) }
                CircleButton(.text("3"), .gray) { append("3", replaceResult: true) }
                CircleButton(.image("plus"), .orange) { append("+") }
            }
            HStack {
                CircleButton(.text("_"), .gray) { append(" ", replaceResult: true) }
                CircleButton(.text("0"), .gray) { append("0", replaceResult: true) }
                CircleButton(.text("."), .gray) { append(".", replaceResult: true) }
                CircleButton(.image("equal"), .orange) { evaluate() }
            }
            HStack {
                CircleButton(.text("ⁿ⁄₂"), .gray) { appendToleratingPrefix("/", "2") }
                CircleButton(.text("ⁿ⁄₄"), .gray) { appendToleratingPrefix("/", "4") }
                CircleButton(.text("ⁿ⁄₈"), .gray) { appendToleratingPrefix("/", "8") }
                CircleButton(.text("ⁿ⁄₁₆"), .gray) { appendToleratingPrefix("/", "16") }
            }
        }
        .padding()
    }
    
    private func evaluate() {
        let result = EvaluatableCalculation.from(input.description)?.evaluate()
        guard let result else {
            return
        }
        
        let (rational, error) = switch result {
        case .rational(let r):
            r.roundedToPrecision(precision)
        case .real(let r):
            r.toNearestRational(withPrecision: precision)
        }
        previous = input.description
        input.set(.result(rational, error))
        isErrorPresented = false
    }
}

struct CircleButton: View {
    enum Content {
        case text(String)
        case image(String)
    }
    
    let content: Content
    let fill: Color
    let action: () -> Void
    
    init(_ content: Content, _ fill: Color, action: @escaping () -> Void) {
        self.content = content
        self.fill = fill
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
            case .image(let image):
                Image(systemName: image)
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .tint(fill)
    }
}

#Preview {
    ContentView()
}
