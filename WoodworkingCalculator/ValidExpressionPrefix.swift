import Foundation

// Exists because there are multi-character sequences that must be trimmed as an atomic unit.
// We want to make sure that callers don't try to chop single characters off the end because they
// might create something very invalid.
//
// As of this writing there are no trim rules that interact with such multi-character sequences, but
// the backspace logic which is related to this does, so I took the opportunity to move all the
// logic here instead.
enum TrimmableCharacterSet {
    case whitespaceAndFractionSlash

    internal var set: Set<Character> {
        switch self {
        case .whitespaceAndFractionSlash: Set([" ", "/"])
        }
    }
}

struct ValidExpressionPrefix: Equatable {
    let value: String

    init() {
        value = ""
    }

    init?(_ string: String) {
        guard EvaluatableCalculation.isValidPrefix(string) else {
            return nil
        }
        value = string
    }

    init(_ inches: Inches, as preferredUnit: UsCustomaryUnit, precision: RationalPrecision) {
        let rounded = inches.toRational(precision: precision).0
        value = if inches.dimension == .unitless {
            inches.toReal().formatted() // TODO: better formatting
        } else if inches.dimension.value == 1 {
            formatOneDimensionalRational(inches: rounded, as: preferredUnit)
        } else {
            formatDecimal(inches: Double(rounded), of: inches.dimension, as: preferredUnit, to: Constants.decimalDigitsOfPrecision)
        }
    }

    var backspaced: ValidExpressionPrefix {
        if let match = value.firstMatch(of: /(in|ft|mm|cm|m)(\[[0-9]+\])?$/) {
            // FIXME: Don't like non-null assertion.
            .init(String(value.prefix(value.count - match.output.0.count)))!
        } else {
            // FIXME: Don't like non-null assertion.
            .init(value.count == 0 ? "" : String(value.prefix(value.count - 1)))!
        }
    }

    func append(_ suffix: String, trimmingSuffix trimmableCharacters: TrimmableCharacterSet? = nil) -> ValidExpressionPrefix? {
        var string = value
        if let trimmableSet = trimmableCharacters?.set {
            while string.count > 0 && trimmableSet.contains(string.last!) {
                string.removeLast()
            }
        }
        return .init((string + suffix).replacing(/\ +/, with: " "))
    }
}
