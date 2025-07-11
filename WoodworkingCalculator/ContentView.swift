import SwiftUI

enum InputValue {
    case string(String)
    case result(Fraction, Double?)
}

struct Input: CustomStringConvertible {
    private var value: InputValue = .string("")
    @AppStorage(Constants.AppStorage.displayInchesOnlyKey) private var displayInchesOnly: Bool = Constants.AppStorage.displayInchesOnlyDefault
    
    mutating func set(_ value: InputValue) {
        self.value = value
    }
    
    mutating func append(_ string: String) {
        value = .string(description + string)
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
    
    private func append(_ string: String) {
        input.append(string)
        previous = ""
    }
    
    var body: some View {
        VStack {
            Image(systemName: "gear")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 32))
                .foregroundStyle(.orange)
                .padding()
                .onTapGesture { isSettingsPresented.toggle() }
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
                    Text("≈")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.red)
                        .padding()
                        .onTapGesture { isErrorPresented.toggle() }
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
                CircleButton(fill: Color.gray, text: input.backspaceable ? "⌫" : "C") {
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
                CircleButton(fill: Color.gray, text: "'") { append("'") }
                CircleButton(fill: Color.gray, text: "\"") { append("\"") }
                CircleButton(fill: Color.orange, text: "÷", size: 48) { append("/") }
            }
            HStack {
                CircleButton(fill: Color.gray, text: "7") { append("7") }
                CircleButton(fill: Color.gray, text: "8") { append("8") }
                CircleButton(fill: Color.gray, text: "9") { append("9") }
                CircleButton(fill: Color.orange, text: "×", size: 48) { append("x") }
            }
            HStack {
                CircleButton(fill: Color.gray, text: "4") { append("4") }
                CircleButton(fill: Color.gray, text: "5") { append("5") }
                CircleButton(fill: Color.gray, text: "6") { append("6") }
                CircleButton(fill: Color.orange, text: "-", size: 48) { append("-") }
            }
            HStack {
                CircleButton(fill: Color.gray, text: "1") { append("1") }
                CircleButton(fill: Color.gray, text: "2") { append("2") }
                CircleButton(fill: Color.gray, text: "3") { append("3") }
                CircleButton(fill: Color.orange, text: "+", size: 48) { append("+") }
            }
            HStack {
                CircleButton(fill: Color.gray, text: "_") { append(" ") }
                CircleButton(fill: Color.gray, text: "0") { append("0") }
                CircleButton(fill: Color.gray, text: ".") { append(".") }
                CircleButton(fill: Color.orange, text: "=", size: 48) { evaluate() }
            }
            HStack {
                CircleButton(fill: Color.gray, text: "ⁿ⁄₂") { append("/2") }
                CircleButton(fill: Color.gray, text: "ⁿ⁄₄") { append("/4") }
                CircleButton(fill: Color.gray, text: "ⁿ⁄₈") { append("/8") }
                CircleButton(fill: Color.gray, text: "ⁿ⁄₁₆") { append("/16") }
            }
        }
        .padding()
    }
    
    private func evaluate() {
        let result = try? parse(input.description).evaluate()
        guard result != nil else {
            return
        }
        
        let (fraction, error) = switch result! {
        case .rational(let r):
            r.roundedToPrecision(precision)
        case .real(let r):
            r.toNearestFraction(withPrecision: precision)
        }
        previous = input.description
        input.set(.result(fraction, error))
        isErrorPresented = false
    }
}

struct CircleButton: View {
    let fill: Color
    let text: String
    let size: Int
    let action: () -> Void
    
    init(fill: Color, text: String, size: Int = 32, action: @escaping () -> Void) {
        self.fill = fill;
        self.text = text;
        self.size = size;
        self.action = action;
    }
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(fill)
                .overlay(content: {
                    Text(text)
                        .foregroundStyle(.white)
                        .font(.system(size: CGFloat(size)))
                })
        }
    }
}

#Preview {
    ContentView()
}
