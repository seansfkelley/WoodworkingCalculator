import SwiftUI

struct ResultReadout: View {
    let input: InputValue
    let formattingOptions: Quantity.FormattingOptions
    @Binding var isErrorPresented: Bool
    @Binding var isRoundingErrorWarningPresented: Bool
    @Binding var shakeError: Bool
    let openSettings: () -> Void

    private var epsilon: Double {
        pow(0.1, Double(Constants.decimalDigitsOfPrecision))
    }

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
                textContent(text: prefix.value)
            }
        case .result(let quantity):
            let (formatted, roundingError) = quantity.formatted(with: formattingOptions)
            HStack {
                if let roundingError, abs(roundingError.error) >= epsilon {
                    Button(action: { isRoundingErrorWarningPresented.toggle() }) {
                        Text("≈")
                            .font(.system(size: 40))
                            .foregroundStyle(.orange)
                            .padding(.bottom, 4)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .popover(isPresented: $isRoundingErrorWarningPresented, arrowEdge: .top) {
                        let actual = prettyPrintExpression(
                            formatDecimal(
                                inches: quantity.toReal(),
                                of: roundingError.dimension,
                                as: formattingOptions.unit,
                                to: Constants.decimalDigitsOfPrecisionExtended,
                            )
                        )
                        let absError = prettyPrintExpression(
                            formatDecimal(
                                inches: abs(roundingError.error),
                                of: roundingError.dimension,
                                as: formattingOptions.unit,
                                to: Constants.decimalDigitsOfPrecisionExtended,
                            )
                        )
                        let precision = prettyPrintExpression(
                            roundingError.dimension == .length
                                ? formatOneDimensionalRational(
                                    inches: roundingError.oneDimensionalPrecision.rational,
                                    as: .inches,
                                )
                                : formatDecimal(
                                    inches: Double(roundingError.dimensionallyAdjustedPrecision.rational),
                                    of: roundingError.dimension,
                                    as: .inches,
                                    to: Constants.decimalDigitsOfPrecision,
                                ),
                            includingFractions: false,
                        )
                        let sign = roundingError.error.sign == .plus ? "+" : "−"

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text("=").font(.title)
                                VStack(spacing: 2) {
                                    Text(actual)
                                        .font(.title)
                                    Text("actual")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.secondary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                                Text(sign).font(.title)
                                VStack(spacing: 2) {
                                    Text(absError)
                                        .font(.title)
                                    Text("error")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.red.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                            }
                            HStack(spacing: 4) {
                                Text("Rounding to \(precision).")
                                    .foregroundStyle(.secondary)
                                Button(action: openSettings) {
                                    Text("Change precision.")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.blue)
                            }
                            .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .presentationCompactAdaptation(.popover)
                    }
                }
                textContent(text: formatted)
            }
        }
    }

    @ViewBuilder
    private func textContent(text: String) -> some View {
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
