import SwiftUI
import ExyteGrid

private let darkGray = Color.gray.mix(with: .black, by: 0.25)
private let gridSpacing = 8

struct ButtonGrid: View {
    let backspacedInput: ValidExpressionPrefix?
    let resetInput: (ValidExpressionPrefix) -> Void
    let append: (String, Bool, TrimmableCharacterSet?) -> Void
    let evaluate: () -> Void
    
    var body: some View {
        Grid(tracks: 4, spacing: GridSpacing(integerLiteral: gridSpacing)) {
            // n.b. GridGroup is only to work around limitations in SwiftUI's ViewBuilder
            // closure typings, but I figured it doubled as a nice way to emphasize the rows.
            GridGroup {
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
                CalculatorButton(.image("divide"), .orange) { append("÷", false, nil) }
            }
            GridGroup {
                CalculatorButton(.text("'"), .gray, action: { append(UsCustomaryUnit.feet.abbreviation, false, nil) })
                    .contextMenu {
                        DimensionButton(.feet, .length) { append($0, false, nil) }
                        DimensionButton(.feet, .area) { append($0, false, nil) }
                        DimensionButton(.feet, .volume) { append($0, false, nil) }
                    }
                CalculatorButton(.text("\""), .gray, action: { append(UsCustomaryUnit.inches.abbreviation, false, nil) })
                    .contextMenu {
                        DimensionButton(.inches, .length) { append($0, false, nil) }
                        DimensionButton(.inches, .area) { append($0, false, nil) }
                        DimensionButton(.inches, .volume) { append($0, false, nil) }
                    }
                CalculatorButton(.text("."), .gray) { append(".", true, nil) }
                CalculatorButton(.image("multiply"), .orange) { append("×", false, nil) }
            }
            GridGroup {
                CalculatorButton(.text("7"), darkGray) { append("7", true, nil) }
                CalculatorButton(.text("8"), darkGray) { append("8", true, nil) }
                CalculatorButton(.text("9"), darkGray) { append("9", true, nil) }
                CalculatorButton(.image("minus"), .orange) { append("-", false, nil) }
            }
            GridGroup {
                CalculatorButton(.text("4"), darkGray) { append("4", true, nil) }
                CalculatorButton(.text("5"), darkGray) { append("5", true, nil) }
                CalculatorButton(.text("6"), darkGray) { append("6", true, nil) }
                CalculatorButton(.image("plus"), .orange) { append("+", false, nil) }
            }
            GridGroup {
                CalculatorButton(.text("1"), darkGray) { append("1", true, nil) }
                CalculatorButton(.text("2"), darkGray) { append("2", true, nil) }
                CalculatorButton(.text("3"), darkGray) { append("3", true, nil) }
            }
            CalculatorButton(.image("equal"), .orange) { evaluate() }.gridSpan(row: 2)
            GridGroup {
                CalculatorButton(.text("␣"), .gray) { append(" ", true, nil) }
                CalculatorButton(.text("0"), darkGray) { append("0", true, nil) }
                CalculatorButton(.text("⁄"), .gray) { append("/", false, .whitespaceAndFractionSlash) }
            }
            GridGroup {
                CalculatorButton(.text("⁄₂"), .gray, contentOffset: CGPoint(x: 4, y: 0)) {
                    append("/2", false, .whitespaceAndFractionSlash)
                }
                CalculatorButton(.text("⁄₄"), .gray, contentOffset: CGPoint(x: 4, y: 0)) {
                    append("/4", false, .whitespaceAndFractionSlash)
                }
                CalculatorButton(.text("⁄₈"), .gray, contentOffset: CGPoint(x: 4, y: 0)) {
                    append("/8", false, .whitespaceAndFractionSlash)
                }
                CalculatorButton(.text("⁄₁₆"), .gray, contentOffset: CGPoint(x: 4, y: 0)) {
                    append("/16", false, .whitespaceAndFractionSlash)
                }
            }
        }
    }
}
