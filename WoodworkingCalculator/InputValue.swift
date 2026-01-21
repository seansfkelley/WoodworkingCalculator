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
    private var value: RawValue = .draft(.init(), nil)
    @AppStorage(Constants.AppStorage.displayInchesOnlyKey)
    private var displayInchesOnly: Bool = Constants.AppStorage.displayInchesOnlyDefault
    @AppStorage(Constants.AppStorage.precisionKey)
    private var precision: Int = Constants.AppStorage.precisionDefault

    var draft: ValidExpressionPrefix {
        switch value {
        case .draft(let draft, _): draft
        case .result(let result): displayInchesOnly
            ? .init(result, as: .inches, precision: precision)
            : .init(result, as: .feet, precision: precision)
        }
    }

    var error: Error? {
        switch value {
        case .result: nil
        case .draft(_, let error): error
        }
    }
    
    var inaccuracy: (Int, Double, Dimension)? {
        switch value {
        case .draft:
            return nil
        case .result(let result):
            let (inaccuracy, dimension) = switch result {
            case .rational(let value, let dimension):
                (value.roundedToDenominator(precision).1, dimension)
            case .real(let value, let dimension):
                (value.toNearestRational(withDenominator: precision).1, dimension)
            }
            if let inaccuracy {
                return (precision, inaccuracy, dimension)
            } else {
                return nil
            }
        }
    }
    
    var meters: Double? {
        return switch value {
        case .draft:
            nil
        case .result(let quantity):
            // Decimal ratio is exact, by definition of the US customary system: 1" = 25.4mm.
            // https://en.wikipedia.org/wiki/United_States_customary_units#International_units
            quantity.toReal() * 0.0254
        }
    }

    var backspaced: BackspaceResult {
        switch value {
        case .draft(let draft, _): .draft(draft.backspaced)
        case .result: .clear
        }
    }

    @discardableResult
    func append(
        _ suffix: String,
        canReplaceResult: Bool = false,
        trimmingSuffix: TrimmableCharacterSet? = nil,
    ) -> Bool {
        let candidate = if canReplaceResult, case .result = value {
            ValidExpressionPrefix(suffix)
        } else {
            draft.append(suffix, trimmingSuffix: trimmingSuffix)
        }
        
        if let candidate, candidate.value.wholeMatch(of: /^\s*$/) == nil && candidate != draft
        {
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
}
