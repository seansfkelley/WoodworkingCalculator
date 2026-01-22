import Foundation
import SwiftUI

enum InputValue {
    case draft(ValidExpressionPrefix, EvaluationError?)
    case result(Quantity)

    var error: EvaluationError? {
        switch self {
        case .draft(_, let error): error
        case .result: nil
        }
    }

    var backspaced: BackspaceOperation {
        switch self {
        case .draft(let draft, _): .draft(draft.backspaced)
        case .result: .clear
        }
    }

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

enum BackspaceOperation: Equatable {
    case clear
    case draft(ValidExpressionPrefix)

    var inputValue: InputValue {
        switch self {
        case .clear: .draft(.init(), nil)
        case .draft(let draft): .draft(draft, nil)
        }
    }

    var buttonText: String {
        switch self {
        case .clear: "C"
        case .draft: "⌫"
        }
    }
}
