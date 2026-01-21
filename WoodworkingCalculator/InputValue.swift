import Foundation
import SwiftUI

class InputValue: ObservableObject {
    enum RawValue {
        case string(String, Error?)
        case result(Quantity)
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
            let (rational, _) = switch r {
            case .rational(let r):
                r.roundedToDenominator(precision)
            case .real(let r):
                r.toNearestRational(withDenominator: precision)
            }
            return formatAsUsCustomary(rational, displayInchesOnly ? .inches : .feet)
        }
    }

    var error: Error? {
        switch value {
        case .result: nil
        case .string(_, let error): error
        }
    }
    
    var inaccuracy: (Int, Double)? {
        switch value {
        case .string:
            return nil
        case .result(let r):
            let (_, inaccuracy) = switch r {
            case .rational(let r):
                r.roundedToDenominator(precision)
            case .real(let r):
                r.toNearestRational(withDenominator: precision)
            }
            if let inaccuracy {
                return (precision, inaccuracy)
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
    
    var willBackspaceSingleCharacter: Bool {
        return switch value {
        case .string(let s, _):
            !s.isEmpty
        case .result:
            false
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
    
    func backspace() {
        value = switch (value) {
        case .string(let s, _):
            .string(s.count == 0 ? "" : String(s.prefix(s.count - 1)), nil)
        case .result:
            .string("", nil)
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
