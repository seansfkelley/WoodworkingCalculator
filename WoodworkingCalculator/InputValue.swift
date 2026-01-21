import Foundation
import SwiftUI

private let multiCharacterBackspaceableSuffix = /(mm|cm)$/

class InputValue: ObservableObject {
    enum RawValue {
        case string(String, EvaluationError?)
        case result(Quantity)
    }

    enum BackspaceResult: Equatable {
        case clear
        case string(String)

        var rawValue: RawValue {
            switch self {
            case .clear: .string("", nil)
            case .string(let s): .string(s, nil)
            }
        }

        var buttonText: String {
            switch self {
            case .clear: "C"
            case .string: "⌫"
            }
        }
    }

    @Published
    private var value: RawValue = .string("", nil)
    @AppStorage(Constants.AppStorage.displayInchesOnlyKey)
    private var displayInchesOnly: Bool = Constants.AppStorage.displayInchesOnlyDefault
    @AppStorage(Constants.AppStorage.precisionKey)
    private var precision: Int = Constants.AppStorage.precisionDefault

    var stringified: String {
        switch value {
        case .string(let s, _):
            return s
        case .result(let r):
            let (rational, dimension) = switch r {
            case .rational(let value, let dimension):
                (value.roundedToDenominator(precision).0, dimension)
            case .real(let value, let dimension):
                (value.toNearestRational(withDenominator: precision).0, dimension)
            }
            return formatAsUsCustomary(rational, dimension, displayInchesOnly ? .inches : .feet)
        }
    }

    var error: Error? {
        switch value {
        case .result: nil
        case .string(_, let error): error
        }
    }
    
    var inaccuracy: (Int, Double, Dimension)? {
        switch value {
        case .string:
            return nil
        case .result(let r):
            let (inaccuracy, dimension) = switch r {
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
        case .string:
            nil
        case .result(let r):
            // Decimal ratio is exact, by definition of the US customary system: 1" = 25.4mm.
            // https://en.wikipedia.org/wiki/United_States_customary_units#International_units
            Double(r) * 0.0254
        }
    }

    var backspaced: BackspaceResult {
        switch value {
        case .string(let s, _):
            if let match = s.firstMatch(of: multiCharacterBackspaceableSuffix) {
                .string(String(s.prefix(s.count - match.output.0.count)))
            } else {
                .string(s.count == 0 ? "" : String(s.prefix(s.count - 1)))
            }
        case .result:
            .clear
        }
    }

    func append(
        _ string: String,
        canReplaceResult: Bool = false,
        deletingSuffix charactersToTrim: Set<Character> = Set()
    ) -> Bool {
        let candidate = {
            if canReplaceResult, case .result = value {
                return string
            } else {
                var s = stringified
                while s.count > 0 && charactersToTrim.contains(s.last.unsafelyUnwrapped) {
                    s.removeLast()
                }
                return (s + string).replacing(/\ +/, with: " ")
            }
        }()
        
        if candidate.wholeMatch(of: /^\s*$/) == nil &&
            candidate != stringified &&
            EvaluatableCalculation.isValidPrefix(candidate)
        {
            value = .string(candidate, nil)
            return true
        } else {
            return false
        }
    }
    
    func reset(_ to: RawValue = .string("", nil)) {
        if case .string(let s, _) = to, !EvaluatableCalculation.isValidPrefix(s) {
            // nothing
        } else {
            value = to
        }
    }
}
