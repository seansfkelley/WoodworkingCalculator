import Foundation
import SwiftUI

class InputValue: ObservableObject {
    enum RawValue {
        case draft(ValidExpressionPrefix, EvaluationError?)
        case result(Inches)
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
        case .draft(let draft, _):
            return draft
        case .result(let result):
            let denominator = precision ^^ result.dimension
            return displayInchesOnly
                ? .init(result, as: .inches, denominator: denominator, epsilon: Constants.epsilon)
                : .init(result, as: .feet, denominator: denominator, epsilon: Constants.epsilon)
        }
    }

    var error: Error? {
        switch value {
        case .result: nil
        case .draft(_, let error): error
        }
    }
    
    var inaccuracy: (Double, Inches)? {
        switch value {
        case .draft:
            return nil
        case .result(let inches):
            switch inches {
            case .rational(let rational, let dimension):
                let precision2 = precision ^^ dimension
                let (_, inaccuracy) = rational.roundedToDenominator(precision2, epsilon: Constants.epsilon)
                return inaccuracy.map {
                    ($0, .rational(UncheckedRational(1, precision2).unsafe, dimension))
                }
            case .real(let real, let dimension):
                let precision2 = precision ^^ dimension
                let (_, inaccuracy) = real.toNearestRational(withDenominator: precision2, epsilon: Constants.epsilon)
                return inaccuracy.map {
                    ($0, .real(1.0 / Double(precision2), dimension))
                }
            }
        }
    }
    
    var meters: Double? {
        return switch value {
        case .draft:
            nil
        case .result(let inches):
            // Decimal ratio is exact, by definition of the US customary system: 1" = 25.4mm.
            // https://en.wikipedia.org/wiki/United_States_customary_units#International_units
            inches.toReal() * 0.0254
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
