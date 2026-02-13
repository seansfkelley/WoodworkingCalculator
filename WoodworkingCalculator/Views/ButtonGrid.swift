import SwiftUI

private let darkGray = Color.gray.mix(with: .black, by: 0.25)

struct ButtonGrid: View {
    let spacing: CGFloat
    let backspacedInput: ValidExpressionPrefix?
    let resetInput: (ValidExpressionPrefix) -> Void
    let append: (String, Bool, TrimmableCharacterSet?) -> Void
    let evaluate: () -> Void

    var body: some View {
        VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                CalculatorButton(.text(backspacedInput == nil ? "C" : "⌫"), .gray, contentOffset: backspacedInput == nil ? .zero : CGPoint(x: -2, y: 0)) {
                    resetInput(backspacedInput ?? .init())
                }
                .simultaneousGesture(LongPressGesture(minimumDuration: 1).onEnded { _ in
                    resetInput(.init())
                })
                CalculatorButton(.text("("), .gray, contentOffset: CGPoint(x: -3, y: -3)) {
                    append("(", true, nil)
                }
                CalculatorButton(.text(")"), .gray, contentOffset: CGPoint(x: 3, y: -3)) {
                    append(")", false, nil)
                }
                CalculatorButton(.image("plus.forwardslash.minus"), .gray) {
                    
                }
            }
            HStack(spacing: spacing) {
                CalculatorButton(.text("'"), .gray, action: { append(UsCustomaryUnit.feet.abbreviation, false, nil) })
                    .contextMenu {
                        DimensionMenuButton(.feet, .length) { append($0, false, nil) }
                        DimensionMenuButton(.feet, .area) { append($0, false, nil) }
                        DimensionMenuButton(.feet, .volume) { append($0, false, nil) }
                    }
                CalculatorButton(.text("\""), .gray, action: { append(UsCustomaryUnit.inches.abbreviation, false, nil) })
                    .contextMenu {
                        DimensionMenuButton(.inches, .length) { append($0, false, nil) }
                        DimensionMenuButton(.inches, .area) { append($0, false, nil) }
                        DimensionMenuButton(.inches, .volume) { append($0, false, nil) }
                    }
                CalculatorButton(.text("."), .gray) { append(".", true, nil) }
                CalculatorButton(.image("divide"), .orange) { append("÷", false, nil) }
            }
            HStack(spacing: spacing) {
                CalculatorButton(.text("7"), darkGray) { append("7", true, .redundantLeadingZeroes) }
                CalculatorButton(.text("8"), darkGray) { append("8", true, .redundantLeadingZeroes) }
                CalculatorButton(.text("9"), darkGray) { append("9", true, .redundantLeadingZeroes) }
                CalculatorButton(.image("multiply"), .orange) { append("×", false, nil) }
            }
            HStack(spacing: spacing) {
                CalculatorButton(.text("4"), darkGray) { append("4", true, .redundantLeadingZeroes) }
                CalculatorButton(.text("5"), darkGray) { append("5", true, .redundantLeadingZeroes) }
                CalculatorButton(.text("6"), darkGray) { append("6", true, .redundantLeadingZeroes) }
                CalculatorButton(.image("minus"), .orange) { append("-", false, nil) }
            }
            HStack(spacing: spacing) {
                CalculatorButton(.text("1"), darkGray) { append("1", true, .redundantLeadingZeroes) }
                CalculatorButton(.text("2"), darkGray) { append("2", true, .redundantLeadingZeroes) }
                CalculatorButton(.text("3"), darkGray) { append("3", true, .redundantLeadingZeroes) }
                CalculatorButton(.image("plus"), .orange) { append("+", false, nil) }
            }
            HStack(spacing: spacing) {
                CalculatorButton(.text("␣"), .gray) { append(" ", true, nil) }
                CalculatorButton(.text("0"), darkGray) { append("0", true, .redundantLeadingZeroes) }
                CalculatorButton(.text("⁄"), .gray) { append("/", false, .whitespaceAndFractionSlash) }
                CalculatorButton(.image("equal"), .orange) { evaluate() }
            }
        }
    }
}

private struct CalculatorButton: View {
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
        .buttonStyle(CalculatorButtonStyle(fill))
        .buttonBorderShape(.roundedRectangle(radius: .infinity))
    }
}

private struct CalculatorButtonStyle: ButtonStyle {
    private let animation = Animation.spring(response: 0.2, dampingFraction: 0.7)

    let fill: Color

    init(_ fill: Color) {
        self.fill = fill
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background((configuration.isPressed ? fill.mix(with: .white, by: 0.3) : fill).animation(animation))
            .clipShape(RoundedRectangle(cornerRadius: .infinity))
            .glassEffect()
            .scaleEffect(configuration.isPressed ? 1.1 : 1.0)
            .animation(animation, value: configuration.isPressed)
    }
}

private struct DimensionMenuButton: View {
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
