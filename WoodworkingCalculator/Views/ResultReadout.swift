import SwiftUI

struct ResultReadout: View {
    let input: InputValue
    let formattingOptions: Quantity.FormattingOptions
    @Binding var isErrorPresented: Bool
    @Binding var isRoundingErrorWarningPresented: Bool
    @Binding var shakeError: Bool

    var body: some View {
        switch input {
        case .draft(let prefix, let error):
            HStack {
                if let error {
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
                }
                mainThing(text: prefix.value)
            }
        case .result(let quantity):
            let (formatted, roundingError) = quantity.formatted(with: formattingOptions)
            HStack {
                if let roundingError, abs(roundingError.error) >= Constants.epsilon {
                    Button(action: { isRoundingErrorWarningPresented.toggle() }) {
                        Text("≈")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.orange)
                            .padding(.bottom, 4)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .popover(isPresented: $isRoundingErrorWarningPresented, arrowEdge: .top) {
                        VStack {
                            let floatFormatString = "%.\(Constants.decimalDigitsOfPrecision)f"
                            let formattedSign = roundingError.error.sign == .plus ? "+" : "-"
                            let formattedUnits = prettyPrintExpression(
                                roundingError.dimension.formatted(withUnit: "in")
                            )
                            let formattedInaccuracy = prettyPrintExpression(
                                "\(String(format: floatFormatString, abs(roundingError.error)))"
                            )
                            let formattedPrecision = prettyPrintExpression(
                                roundingError.dimension == .length
                                ? roundingError.dimensionallyAdjustedPrecision.rational.formatted
                                : String(format: floatFormatString, Double(roundingError.dimensionallyAdjustedPrecision.rational))
                            )
                            Text("Rounding error: \(formattedSign)\(formattedInaccuracy)")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer()
                            Text("""
                                actual \(formattedSign) \(formattedInaccuracy)\(formattedUnits) \
                                = \
                                \(prettyPrintExpression(formatted))
                                """)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Divider()
                            Text("Rounded to the nearest \(formattedPrecision)\(formattedUnits)")
                                .font(.system(.callout))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .presentationCompactAdaptation(.popover)
                    }
                }
                mainThing(text: formatted)
            }
        }
    }

    @ViewBuilder
    private func mainThing(text: String) -> some View {
        Text(appendTrailingParentheses(to: prettyPrintExpression(text)))
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
}

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
