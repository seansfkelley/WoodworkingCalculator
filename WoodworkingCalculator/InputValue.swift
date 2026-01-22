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

    enum MetricStatus: Equatable {
        case insertable
        case convertible(Double) // meters
        case unavailable
    }

    struct FormattingOptions {
        let unit: UsCustomaryUnit
        let precision: RationalPrecision

        init(_ unit: UsCustomaryUnit, _ precision: RationalPrecision) {
            self.unit = unit
            self.precision = precision
        }
    }

    @Published
    private var value: RawValue = .draft(.init(), nil)

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

    func formatted(with options: FormattingOptions) -> (String, Quantity.RoundingError?) {
        switch value {
        case .draft(let draft, _):
            (draft.value, nil)
        case .result(let quantity):
            quantity.formatted(
                as: options.unit,
                to: options.precision,
                toDecimalPrecision: Constants.decimalDigitsOfPrecision,
            )
        }
    }

    var meters: MetricStatus {
        switch value {
        case .draft(let prefix, _):
            // Don't use "m" because if there's a trailing "m" already, appending it would weirdly
            // create the valid "mm".
            if prefix.append("mm") != nil {
                .insertable
            } else {
                .unavailable
            }
        case .result(let quantity):
            if let meters = quantity.meters {
                .convertible(meters)
            } else {
                .unavailable
            }
        }
    }

    @discardableResult
    func append(
        _ suffix: String,
        with options: FormattingOptions,
        canReplaceResult: Bool = false,
        trimmingSuffix: TrimmableCharacterSet? = nil,
    ) -> Bool {
        let currentDraft = switch value {
        case .result(let quantity):
            ValidExpressionPrefix(quantity, as: options.unit, precision: options.precision)
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

    @discardableResult
    func setError(to error: EvaluationError?) -> Bool {
        switch value {
        case .draft(let  prefix, _):
            value = .draft(prefix, error)
            return true
        case .result:
            return false
        }
    }
}
