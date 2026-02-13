import Foundation
import SwiftUI

enum InputValue {
    case draft(ValidExpressionPrefix, EvaluationError?)
    case result(EvaluationResult)

    func inverted(
        formattingResultWith formatOptions: Quantity.FormattingOptions,
        assumeInches: Bool,
    ) -> InputValue? {
        switch self {
        case .result(let result):
            let formatted = result
                .quantity(assumingLengthIf: assumeInches)
                .formatted(with: formatOptions)
                .0

            let toggled = formatted.hasPrefix("-") ? String(formatted.dropFirst()) : "-" + formatted
            return ValidExpressionPrefix(toggled).map { .draft($0, nil) }
        case .draft(let prefix, _):
            guard let calculation = EvaluatableCalculation.from(prefix.value),
                  isSingleNumber(calculation) else {
                return nil
            }
            let toggled = prefix.value.hasPrefix("-") ? String(prefix.value.dropFirst()) : "-" + prefix.value
            return ValidExpressionPrefix(toggled).map { .draft($0, nil) }
        }
    }

    func appending(
        suffix: String,
        formattingResultWith formatOptions: Quantity.FormattingOptions,
        assumeInches: Bool,
        allowingResultReplacement canReplaceResult: Bool = false,
        trimmingSuffix: TrimmableCharacterSet? = nil,
    ) -> InputValue? {
        let currentDraft = switch self {
        case .result(let result):
            ValidExpressionPrefix(result.quantity(assumingLengthIf: assumeInches), with: formatOptions)
        case .draft(let prefix, _):
            prefix
        }

        let candidate = if canReplaceResult, case .result = self {
            ValidExpressionPrefix(suffix)
        } else {
            currentDraft.append(suffix, trimmingSuffix: trimmingSuffix)
        }

        return if let candidate, candidate.value.wholeMatch(of: /^\s*$/) == nil && candidate != currentDraft {
            .draft(candidate, nil)
        } else {
            nil
        }
    }
}

private func isSingleNumber(_ calculation: EvaluatableCalculation) -> Bool {
    switch calculation {
    case .rational, .real: true
    case .negate(let inner):
        switch inner {
        case .rational, .real: true
        default: false
        }
    default: false
    }
}
