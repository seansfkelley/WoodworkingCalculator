import Foundation
import SwiftUI

class InputValue: ObservableObject {
    enum RawValue {
        case draft(ValidExpressionPrefix, EvaluationError?)
        case result(Quantity)
    }

    enum BackspaceResult: Equatable {
        case clear
        case draft(ValidExpressionPrefix)

        var rawValue: RawValue {
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

    @Published
    var value: RawValue = .draft(.init(), nil)
    @AppStorage(Constants.AppStorage.displayInchesOnlyKey)
    private var displayInchesOnly: Bool = Constants.AppStorage.displayInchesOnlyDefault
    @AppStorage(Constants.AppStorage.precisionKey)
    private var precision: RationalPrecision = Constants.AppStorage.precisionDefault

    var backspaced: BackspaceResult {
        switch value {
        case .draft(let draft, _): .draft(draft.backspaced)
        case .result: .clear
        }
    }

    var error: EvaluationError? {
        switch value {
        case .draft(_, let error): error
        case .result: nil
        }
    }

    var formatted: (String, Quantity.RoundingError?) {
        switch value {
        case .draft(let draft, _):
            (draft.value, nil)
        case .result(let quantity):
            quantity.formatted(
                as: displayInchesOnly ? .inches : .feet,
                to: precision,
                toDecimalPrecision: Constants.decimalDigitsOfPrecision,
            )
        }
    }

    @discardableResult
    func append(
        _ suffix: String,
        canReplaceResult: Bool = false,
        trimmingSuffix: TrimmableCharacterSet? = nil,
    ) -> Bool {
        let currentDraft = switch value {
        case .result(let quantity):
            displayInchesOnly
                ? ValidExpressionPrefix(quantity, as: .inches, precision: precision)
                : ValidExpressionPrefix(quantity, as: .feet, precision: precision)
        case .draft(let prefix, _):
            prefix
        }

        let candidate = if canReplaceResult, case .result = value {
            ValidExpressionPrefix(suffix)
        } else {
            currentDraft.append(suffix, trimmingSuffix: trimmingSuffix)
        }

        if let candidate, candidate.value.wholeMatch(of: /^\s*$/) == nil && candidate != currentDraft {
            value = .draft(candidate, nil)
            return true
        } else {
            return false
        }
    }

    @discardableResult
    func setValue(to: RawValue? = .draft(.init(), nil)) -> Bool {
        if let to {
            value = to
            return true
        } else {
            return false
        }
    }

    func evaluate() -> Result<ValidExpressionPrefix?, EvaluationError> {
        let string = formatted.0
        switch value {
        case .result:
            return .success(.init(string))
        case .draft(let expression, _):
            let missingParens = EvaluatableCalculation.countMissingTrailingParens(string)
            let formattedInputString = string.trimmingCharacters(in: CharacterSet.whitespaces) + String(repeating: ")", count: missingParens)
            let result = EvaluatableCalculation.from(formattedInputString)?.evaluate()
            guard let result else {
                return .failure(.syntaxError)
            }

            switch result {
            case .success(let answer):
                value = .result(answer)
                return .success(.init(formattedInputString))
            case .failure(let error):
                value = .draft(expression, error)
                return .failure(error)
            }
        }
    }
}
