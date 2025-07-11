import SwiftUI

struct ContentView: View {
    @State private var previous: String = ""
    @State private var error: String = ""
    @State private var input: String = ""
    @State private var isSettingsPresented: Bool = false
    
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
                    self.input = previous
                    self.previous = ""
                }
            HStack {
                if !error.isEmpty {
                    Image(systemName: "notequal.circle")
                        .font(.system(size: 32))
                        .foregroundColor(Color.yellow)
                        .padding()
                }
                Text(input)
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
                Button(fill: Color.gray, text: "C") {
                    self.previous = ""
                    self.input = ""
                    self.error = ""
                }
                Button(fill: Color.gray, text: "'") { self.input.append("'") }
                Button(fill: Color.gray, text: "\"") { self.input.append("\"") }
                Button(fill: Color.orange, text: "÷", size: 48) { self.input.append("/") }
            }
            HStack {
                Button(fill: Color.gray, text: "7") { self.input.append("7") }
                Button(fill: Color.gray, text: "8") { self.input.append("8") }
                Button(fill: Color.gray, text: "9") { self.input.append("9") }
                Button(fill: Color.orange, text: "×") { self.input.append("x") }
            }
            HStack {
                Button(fill: Color.gray, text: "4") { self.input.append("4") }
                Button(fill: Color.gray, text: "5") { self.input.append("5") }
                Button(fill: Color.gray, text: "6") { self.input.append("6") }
                Button(fill: Color.orange, text: "-") { self.input.append("-") }
            }
            HStack {
                Button(fill: Color.gray, text: "1") { self.input.append("1") }
                Button(fill: Color.gray, text: "2") { self.input.append("2") }
                Button(fill: Color.gray, text: "3") { self.input.append("3") }
                Button(fill: Color.orange, text: "+") { self.input.append("+") }
            }
            HStack {
                Button(fill: Color.gray, text: "_") { self.input.append(" ") }
                Button(fill: Color.gray, text: "0") { self.input.append("0") }
                Button(fill: Color.gray, text: ".") { self.input.append(".") }
                Button(fill: Color.orange, text: "=") { self.evaluate() }
            }
            HStack {
                Button(fill: Color.gray, text: "ⁿ⁄₂\"") { self.input.append("/2\"") }
                Button(fill: Color.gray, text: "ⁿ⁄₄\"") { self.input.append("/4\"") }
                Button(fill: Color.gray, text: "ⁿ⁄₈\"") { self.input.append("/8\"") }
                Button(fill: Color.gray, text: "ⁿ⁄₁₆\"") { self.input.append("/16\"") }
            }
        }
        .padding()
    }
    
    private func evaluate() {
        let result = try? parse(input).evaluate()
        guard result != nil else {
            return
        }
        
        let (fraction, error) = switch result! {
        case .rational(let r):
            r.roundedToPrecision(HIGHEST_PRECISION)
        case .real(let r):
            r.toNearestFraction(withPrecision: HIGHEST_PRECISION)
        }
        self.previous = self.input
        self.input = formatAsUsCustomary(fraction)
        self.error = if let error { "approximation: \(String(format: "%+.3f", error))\"" } else { "" }
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
