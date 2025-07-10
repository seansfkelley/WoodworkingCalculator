import SwiftUI

struct ContentView: View {
    @State private var input: String = "";
    
    var body: some View {
        VStack {
            Text(input)
                .frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    minHeight: 0,
                    maxHeight: .infinity,
                    alignment: .trailing
                )
                .font(.system(size: 100, weight: .light))
//                .scaledToFill()
            HStack {
                Button(fill: Color.gray, text: "C") { self.input = "" }
                Button(fill: Color.gray, text: "'") { self.input.append("'") }
                Button(fill: Color.gray, text: "\"") { self.input.append("\"") }
                Button(fill: Color.orange, text: "/") { self.input.append("/") }
            }
            HStack {
                Button(fill: Color.gray, text: "7") { self.input.append("7") }
                Button(fill: Color.gray, text: "8") { self.input.append("8") }
                Button(fill: Color.gray, text: "9") { self.input.append("9") }
                Button(fill: Color.orange, text: "x") { self.input.append("x") }
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
                Button(fill: Color.gray, text: "_") { self.input.append("_") }
                Button(fill: Color.gray, text: "0") { self.input.append("0") }
                Button(fill: Color.gray, text: ".") { self.input.append(".") }
                Button(fill: Color.orange, text: "=") { self.input.append("=") }
            }
            HStack {
                Button(fill: Color.gray, text: "/2") { self.input.append("/2") }
                Button(fill: Color.gray, text: "/4") { self.input.append("/4") }
                Button(fill: Color.gray, text: "/8") { self.input.append("/8") }
                Button(fill: Color.gray, text: "/16") { self.input.append("/16") }
            }
        }
        .padding()
    }
}

struct Button: View {
    let fill: Color;
    let text: String;
    let action: (() -> Void)?;
    
    init(fill: Color, text: String, action: (() -> Void)? = nil) {
        self.fill = fill;
        self.text = text;
        self.action = action;
    }
    
    var body: some View {
        Circle()
            .fill(fill)
//            .frame(width: 80, height: 80)
            .overlay(content: {
                Text(text)
                    .foregroundColor(.white)
                    .font(.system(size: 32, weight: .bold))
            })
            .onTapGesture { action?() }
    }
}

#Preview {
    ContentView()
}
