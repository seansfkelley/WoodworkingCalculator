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

// The only reason this is separated from InputValue is because we don't want to be forced to carry
// a potential error around for storing an input string in history. Minorly, we also don't want to
// conflate results with inputs, which InputValue is intended to gloss over.
struct ValidExpressionPrefix: Equatable, CustomStringConvertible {
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

    init(_ quantity: Quantity, with options: Quantity.FormattingOptions) {
        value = quantity.formatted(with: options).0
    }

    var description: String { value }

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
