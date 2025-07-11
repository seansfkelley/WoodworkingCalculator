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
    @State private var input: Input = Input()
    @AppStorage(Constants.AppStorage.displayInchesOnlyKey) private var displayInchesOnly: Bool = Constants.AppStorage.displayInchesOnlyDefault
    
    private func append(_ string: String) {
        input.append(string)
        previous = ""
    }
    
    var body: some View {
        VStack {
            Image(systemName: "gear")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 32))
                .foregroundColor(Color.orange)
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
                .foregroundColor(Color.gray)
                .minimumScaleFactor(0.3)
                .onTapGesture {
                    input.set(.string(previous))
                    previous = ""
                }
            HStack {
                if input.error != nil {
                    Image(systemName: "notequal.circle")
                        .font(.system(size: 32))
                        .foregroundColor(Color.yellow)
                        .padding()
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
                if input.backspaceable {
                    Button(fill: Color.gray, text: "⌫") {
                        previous = ""
                        input.backspace()
                    }
                } else {
                    Button(fill: Color.gray, text: "C") {
                        previous = ""
                        input.set(.string(""))
                    }
                }
                Button(fill: Color.gray, text: "'") { append("'") }
                Button(fill: Color.gray, text: "\"") { append("\"") }
                Button(fill: Color.orange, text: "÷", size: 48) { append("/") }
            }
            HStack {
                Button(fill: Color.gray, text: "7") { append("7") }
                Button(fill: Color.gray, text: "8") { append("8") }
                Button(fill: Color.gray, text: "9") { append("9") }
                Button(fill: Color.orange, text: "×") { append("x") }
            }
            HStack {
                Button(fill: Color.gray, text: "4") { append("4") }
                Button(fill: Color.gray, text: "5") { append("5") }
                Button(fill: Color.gray, text: "6") { append("6") }
                Button(fill: Color.orange, text: "-") { append("-") }
            }
            HStack {
                Button(fill: Color.gray, text: "1") { append("1") }
                Button(fill: Color.gray, text: "2") { append("2") }
                Button(fill: Color.gray, text: "3") { append("3") }
                Button(fill: Color.orange, text: "+") { append("+") }
            }
            HStack {
                Button(fill: Color.gray, text: "_") { append(" ") }
                Button(fill: Color.gray, text: "0") { append("0") }
                Button(fill: Color.gray, text: ".") { append(".") }
                Button(fill: Color.orange, text: "=") { self.evaluate() }
            }
            HStack {
                Button(fill: Color.gray, text: "ⁿ⁄₂") { append("/2") }
                Button(fill: Color.gray, text: "ⁿ⁄₄") { append("/4") }
                Button(fill: Color.gray, text: "ⁿ⁄₈") { append("/8") }
                Button(fill: Color.gray, text: "ⁿ⁄₁₆") { append("/16") }
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
            r.roundedToPrecision(HIGHEST_PRECISION)
        case .real(let r):
            r.toNearestFraction(withPrecision: HIGHEST_PRECISION)
        }
        self.previous = input.description
        self.input.set(.result(fraction, error))
    }
}

struct Button: View {
    let fill: Color;
    let text: String;
    let size: Int;
    let action: (() -> Void)?;
    
    init(fill: Color, text: String, size: Int = 32, action: (() -> Void)? = nil) {
        self.fill = fill;
        self.text = text;
        self.size = size;
        self.action = action;
    }
    
    var body: some View {
        Circle()
            .fill(fill)
            .overlay(content: {
                Text(text)
                    .foregroundColor(.white)
                    .font(.system(size: CGFloat(size)))
            })
            .onTapGesture { action?() }
    }
}

#Preview {
    ContentView()
}
