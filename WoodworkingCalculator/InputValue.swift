import Foundation
import SwiftUI

enum InputValue {
    case draft(ValidExpressionPrefix, EvaluationError?)
    case result(Quantity)

    func appending(
        suffix: String,
        formattingResultWith formatOptions: Quantity.FormattingOptions,
        allowingResultReplacement canReplaceResult: Bool = false,
        trimmingSuffix: TrimmableCharacterSet? = nil,
    ) -> InputValue? {
        let currentDraft = switch self {
        case .result(let quantity):
            ValidExpressionPrefix(quantity, with: formatOptions)
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
